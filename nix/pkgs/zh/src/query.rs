use std::cmp::Reverse;
use std::collections::HashMap;
use std::io::{self, BufWriter, ErrorKind, Write};
use std::path::PathBuf;

use rusqlite::{Connection, params_from_iter};

use crate::{Fail, FilterArgs, Source, db, record, repo, when, zsh};

/// SQL predicates plus the values they bind, in `?N` order.
#[derive(Debug, Default, PartialEq)]
struct Scope {
    conditions: Vec<String>,
    params: Vec<String>,
}

impl Scope {
    fn bind(&mut self, value: &str) -> usize {
        self.params.push(value.to_owned());
        self.params.len()
    }

    fn dir(&mut self, dir: &str) {
        // Strip trailing slashes so "DIR/" prefix matching works, and let the
        // root match everything rather than looking for "//".
        let trimmed = dir.trim_end_matches('/');
        if trimmed.is_empty() && !dir.is_empty() {
            return;
        }
        let dir = trimmed;
        let n = self.bind(dir);
        self.conditions.push(format!(
            "cwd = ?{n} OR substr(cwd, 1, length(?{n}) + 1) = ?{n} || '/'"
        ));
    }

    fn equals(&mut self, column: &str, value: &str) {
        let n = self.bind(value);
        self.conditions.push(format!("{column} = ?{n}"));
    }

    fn from_filters(filters: &FilterArgs) -> Self {
        let mut scope = Scope::default();
        for dir in &filters.dir {
            scope.dir(dir);
        }
        for dir in &filters.repo {
            scope.dir(&repo::root(dir));
        }
        for agent in &filters.agent {
            scope.equals("agent", agent);
        }
        for session in &filters.session {
            scope.equals("session", session);
        }
        scope
    }

    /// Scope plus visibility: failed calls are hidden unless `--all`.
    fn visible(filters: &FilterArgs) -> Self {
        let mut scope = Scope::from_filters(filters);
        if !filters.all {
            scope.conditions.push("status != 'failed'".into());
        }
        scope
    }

    /// Each predicate is parenthesised so an OR inside one cannot escape the
    /// AND.
    fn where_clause(&self) -> String {
        let mut clause = String::new();
        for (i, condition) in self.conditions.iter().enumerate() {
            let keyword = if i == 0 { "WHERE" } else { "AND" };
            clause.push_str(&format!(" {keyword} ({condition})"));
        }
        clause
    }
}

/// A trimmed "YYYY-MM-DD HH:MM" in local time, or "null" where SQLite's
/// strftime gives up (timestamps outside its range), as jq printed it.
const TIME: &str = "strftime('%Y-%m-%d %H:%M', ts, 'unixepoch', 'localtime')";

fn show_time(time: Option<String>) -> String {
    time.unwrap_or_else(|| "null".into())
}

fn read_fail(path: &std::path::Path) -> impl Fn(rusqlite::Error) -> Fail + '_ {
    move |error| Fail::new(format!("could not read {}: {error}", path.display()))
}

/// Writes to stdout; a reader that goes away (fzf closing the pipe) ends the
/// output quietly, any other write error fails.
fn emit(write: impl FnOnce(&mut BufWriter<io::StdoutLock>) -> io::Result<()>) -> Result<(), Fail> {
    let mut out = BufWriter::new(io::stdout().lock());
    match write(&mut out).and_then(|()| out.flush()) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == ErrorKind::BrokenPipe => Ok(()),
        Err(error) => Err(Fail::new(format!("could not write output: {error}"))),
    }
}

pub fn list(filters: &FilterArgs) -> Result<(), Fail> {
    let Some((conn, path)) = db::open_existing()? else {
        return Ok(());
    };
    let scope = Scope::visible(filters);
    // Agents repeat the same commands constantly, so by default each command
    // appears once, at its newest occurrence within the filters.
    let newest_only = if filters.all { "" } else { "WHERE n = 1" };
    let sql = format!(
        "SELECT {TIME} AS time, cwd, cmd FROM (
            SELECT id, ts, cwd, cmd,
                ROW_NUMBER() OVER (PARTITION BY cmd ORDER BY ts DESC, id DESC) AS n
            FROM commands{}
        ) {newest_only}
        ORDER BY ts DESC, id DESC",
        scope.where_clause()
    );
    let fail = read_fail(&path);
    let mut stmt = conn.prepare(&sql).map_err(&fail)?;
    let mut rows = stmt.query(params_from_iter(&scope.params)).map_err(&fail)?;
    let mut failure = None;
    emit(|out| {
        loop {
            let row = match rows.next() {
                Ok(Some(row)) => row,
                Ok(None) => return Ok(()),
                Err(error) => {
                    failure = Some(fail(error));
                    return Ok(());
                }
            };
            let fields: rusqlite::Result<(Option<String>, String, String)> =
                (|| Ok((row.get(0)?, row.get(1)?, row.get(2)?)))();
            let (time, cwd, cmd) = match fields {
                Ok(fields) => fields,
                Err(error) => {
                    failure = Some(fail(error));
                    return Ok(());
                }
            };
            // Rows are tab-delimited and the command is everything after the
            // third tab, so a tab in the directory would shift it; the
            // directory column is only displayed, so show tabs as a symbol.
            let cwd = cwd.replace('\t', "\u{2409}");
            write!(out, "\t{}\t{cwd}\t{cmd}\0", show_time(time))?;
        }
    })?;
    failure.map_or(Ok(()), Err)
}

/// The preview for a picker row. It takes the picker's filters so the
/// metadata comes from the row being shown, not a newer run of the same
/// command outside that scope.
pub fn show(filters: &FilterArgs, cmd: &str) -> Result<(), Fail> {
    let Some((conn, path)) = db::open_existing()? else {
        return Ok(());
    };
    let mut scope = Scope::visible(filters);
    scope.equals("cmd", cmd);
    let sql = format!(
        "SELECT {TIME}, agent, status, cwd, session, description, cmd
         FROM commands{} ORDER BY ts DESC, id DESC LIMIT 1",
        scope.where_clause()
    );
    let fail = read_fail(&path);
    let mut stmt = conn.prepare(&sql).map_err(&fail)?;
    let mut rows = stmt.query(params_from_iter(&scope.params)).map_err(&fail)?;
    let Some(row) = rows.next().map_err(&fail)? else {
        return Ok(());
    };
    let record = (|| -> rusqlite::Result<[String; 6]> {
        Ok([
            show_time(row.get(0)?),
            row.get(1)?,
            row.get(2)?,
            row.get(3)?,
            row.get(4)?,
            row.get(5)?,
        ])
    })()
    .map_err(&fail)?;
    let command: String = row.get(6).map_err(&fail)?;
    let [time, agent, status, cwd, session, description] = record;
    emit(|out| {
        writeln!(out, "{time}  {agent}  {status}")?;
        writeln!(out, "dir: {cwd}")?;
        if !session.is_empty() {
            writeln!(out, "session: {session}")?;
        }
        if !description.is_empty() {
            writeln!(out, "description: {description}")?;
        }
        writeln!(out)?;
        writeln!(out, "{command}")
    })
}

/// Removes every copy so an older duplicate cannot take the forgotten row's
/// place in the deduplicated list. secure_delete overwrites the freed content
/// and the checkpoint folds the WAL back into the database, but a busy
/// checkpoint is skipped, so this is logical deletion with best-effort
/// scrubbing, not secure erasure. Nothing matching is success: another picker
/// may have removed it first.
pub fn forget(cmd: &str) -> Result<(), Fail> {
    let Some((conn, path)) = db::open_existing()? else {
        return Ok(());
    };
    let fail =
        |error: rusqlite::Error| Fail::new(format!("could not write {}: {error}", path.display()));
    conn.query_row("PRAGMA secure_delete = ON", [], |_| Ok(()))
        .map_err(fail)?;
    let count = conn
        .execute("DELETE FROM commands WHERE cmd = ?1", [cmd])
        .map_err(fail)?;
    let _ = conn.query_row("PRAGMA wal_checkpoint(TRUNCATE)", [], |_| Ok(()));
    eprintln!("zh: forgot {count} records");
    Ok(())
}

/// Where the newest entry of a group came from, compared as a whole:
/// timestamp, then agent records above shell entries at the same second,
/// then the agent row id or the shell entry's position in the file.
type Newest = (i64, u8, i64);

const SHELL: u8 = 0;
const AGENT: u8 = 1;

#[derive(Debug, PartialEq)]
struct Group {
    count: usize,
    failed: usize,
    newest: Newest,
}

/// First `words` whitespace-separated words joined by one space. The iterator
/// stops after them, so long heredocs cost nothing.
fn prefix(cmd: &str, words: usize) -> String {
    cmd.split_whitespace()
        .take(words)
        .collect::<Vec<_>>()
        .join(" ")
}

/// Commands folded into per-prefix groups as they stream past; nothing keeps
/// whole commands around.
struct Groups {
    words: usize,
    map: HashMap<String, Group>,
}

impl Groups {
    fn new(words: usize) -> Self {
        Groups {
            words,
            map: HashMap::new(),
        }
    }

    fn add(&mut self, cmd: &str, failed: bool, newest: Newest) {
        let group = self.map.entry(prefix(cmd, self.words)).or_insert(Group {
            count: 0,
            failed: 0,
            newest,
        });
        group.count += 1;
        group.failed += usize::from(failed);
        group.newest = group.newest.max(newest);
    }

    /// Most used first; ties go to the most recently used, then by prefix,
    /// one key compared as a whole so the order is total.
    fn sorted(self) -> Vec<(String, Group)> {
        let mut groups: Vec<_> = self.map.into_iter().collect();
        groups.sort_by(|(a_prefix, a), (b_prefix, b)| {
            (Reverse(a.count), Reverse(a.newest), a_prefix).cmp(&(
                Reverse(b.count),
                Reverse(b.newest),
                b_prefix,
            ))
        });
        groups
    }
}

pub struct StatsArgs {
    pub filters: FilterArgs,
    pub words: usize,
    pub limit: usize,
    pub source: Option<Source>,
    pub histfile: Option<PathBuf>,
    pub since: Option<String>,
    pub until: Option<String>,
}

fn usage(message: impl Into<String>) -> Fail {
    Fail {
        code: 64,
        message: message.into(),
    }
}

/// zsh history has no directory, agent or session, so those filters only
/// make sense for agent records: they select agents when no source is
/// given, and are an error with one that includes the shell, so a total
/// never mixes filtered and unfiltered entries.
fn resolve_source(args: &StatsArgs) -> Result<Source, Fail> {
    let f = &args.filters;
    let agent_only =
        !(f.dir.is_empty() && f.repo.is_empty() && f.agent.is_empty() && f.session.is_empty());
    let source = match (args.source, agent_only) {
        (None, true) => Source::Agents,
        (None, false) => Source::All,
        (Some(Source::Agents), _) => Source::Agents,
        (Some(_), true) => {
            return Err(usage(
                "--dir, --repo, --agent and --session apply to agent records only; use --source agents",
            ));
        }
        (Some(source), false) => source,
    };
    if source == Source::Agents && args.histfile.is_some() {
        return Err(usage("--histfile needs --source shell or all"));
    }
    Ok(source)
}

fn in_range(ts: Option<i64>, (since, until): (Option<i64>, Option<i64>)) -> bool {
    if since.is_none() && until.is_none() {
        return true;
    }
    // Entries without a timestamp cannot be placed in a range.
    let Some(ts) = ts else { return false };
    since.is_none_or(|s| ts >= s) && until.is_none_or(|u| ts < u)
}

fn add_agents(
    groups: &mut Groups,
    filters: &FilterArgs,
    range: (Option<i64>, Option<i64>),
) -> Result<(), Fail> {
    let Some((conn, path)) = db::open_existing()? else {
        return Ok(());
    };
    let mut scope = Scope::from_filters(filters);
    if let Some(since) = range.0 {
        let n = scope.bind(&since.to_string());
        scope
            .conditions
            .push(format!("ts >= CAST(?{n} AS INTEGER)"));
    }
    if let Some(until) = range.1 {
        let n = scope.bind(&until.to_string());
        scope.conditions.push(format!("ts < CAST(?{n} AS INTEGER)"));
    }
    let sql = format!(
        "SELECT id, ts, status, cmd FROM commands{}",
        scope.where_clause()
    );
    let fail = read_fail(&path);
    let mut stmt = conn.prepare(&sql).map_err(&fail)?;
    let mut rows = stmt.query(params_from_iter(&scope.params)).map_err(&fail)?;
    while let Some(row) = rows.next().map_err(&fail)? {
        let (id, ts, status, cmd): (i64, i64, String, String) = (
            row.get(0).map_err(&fail)?,
            row.get(1).map_err(&fail)?,
            row.get(2).map_err(&fail)?,
            row.get(3).map_err(&fail)?,
        );
        groups.add(&cmd, status == "failed", (ts, AGENT, id));
    }
    Ok(())
}

fn add_shell(
    groups: &mut Groups,
    histfile: Option<PathBuf>,
    range: (Option<i64>, Option<i64>),
) -> Result<(), Fail> {
    let path = match histfile {
        Some(path) => path,
        None => db::zdotdir()?.join(".zsh_history"),
    };
    let bytes = match std::fs::read(&path) {
        Ok(bytes) => bytes,
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok(()),
        Err(error) => {
            return Err(Fail::new(format!(
                "could not read {}: {error}",
                path.display()
            )));
        }
    };
    let mut position = 0;
    zsh::for_each_entry(&bytes, |entry| {
        position += 1;
        // A prefix of a typed command can hold a secret as easily as an
        // agent's can; the filter is best-effort for both.
        if in_range(entry.ts, range) && !record::is_secret(&entry.cmd) {
            groups.add(&entry.cmd, false, (entry.ts.unwrap_or(0), SHELL, position));
        }
    });
    Ok(())
}

/// Groups every entry in scope, failed agent calls included, by the first N
/// words of its command. Words are whitespace runs, not shell syntax, so an
/// env prefix or `cd x &&` counts as words. The failed column counts calls
/// Claude reported through PostToolUseFailure: worth a look, not a list of
/// denials; zsh records no exit status, so shell entries never count there.
/// Shell counts are the entries zsh kept, which the HIST_*_DUPS options thin
/// out, not every execution.
pub fn stats(args: &StatsArgs) -> Result<(), Fail> {
    let source = resolve_source(args)?;
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    let range = when::range(args.since.as_deref(), args.until.as_deref(), now).map_err(usage)?;
    let mut groups = Groups::new(args.words);
    if source != Source::Shell {
        add_agents(&mut groups, &args.filters, range)?;
    }
    if source != Source::Agents {
        add_shell(&mut groups, args.histfile.clone(), range)?;
    }
    let groups = groups.sorted();
    emit(|out| {
        for (prefix, group) in groups.iter().take(args.limit) {
            writeln!(out, "{}\t{}\t{prefix}", group.count, group.failed)?;
        }
        Ok(())
    })
}

fn default_atuin_db() -> Result<PathBuf, Fail> {
    let data = match std::env::var_os("XDG_DATA_HOME").filter(|d| !d.is_empty()) {
        Some(dir) => PathBuf::from(dir),
        None => {
            PathBuf::from(std::env::var_os("HOME").ok_or_else(|| Fail::new("HOME is not set"))?)
                .join(".local/share")
        }
    };
    Ok(data.join("atuin/history.db"))
}

/// atuin marks agent-run commands with author_kind 2 and applied the same
/// credential filters when recording them, so rows are copied as they are.
/// Re-running skips rows that are already present.
pub fn import_atuin(path: Option<PathBuf>) -> Result<(), Fail> {
    let src = match path {
        Some(path) => path,
        None => default_atuin_db()?,
    };
    if std::fs::File::open(&src).is_err() {
        return Err(Fail::new(format!("no atuin database at {}", src.display())));
    }
    let (conn, _) = db::open_or_create()?;
    let imported = import_from(&conn, &src)
        .map_err(|error| Fail::new(format!("could not import from {}: {error}", src.display())))?;
    emit(|out| {
        writeln!(
            out,
            "zh: imported {imported} commands from {}",
            src.display()
        )
    })
}

fn import_from(conn: &Connection, src: &std::path::Path) -> rusqlite::Result<usize> {
    conn.execute("ATTACH DATABASE ?1 AS atuin", [src.to_string_lossy()])?;
    let imported = conn.execute(
        "INSERT INTO commands (ts, agent, cwd, cmd)
         SELECT h.timestamp / 1000000000,
             CASE h.author WHEN 'claude-code' THEN 'claude' ELSE h.author END,
             h.cwd, h.command
         FROM atuin.history AS h
         WHERE h.author_kind = 2 AND h.deleted_at IS NULL
             AND NOT EXISTS (
                 SELECT 1 FROM commands AS c
                 WHERE c.ts = h.timestamp / 1000000000 AND c.cwd = h.cwd AND c.cmd = h.command)
         ORDER BY h.timestamp",
        [],
    )?;
    conn.execute("DETACH DATABASE atuin", [])?;
    Ok(imported)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dir_filters_normalise_slashes() {
        let mut scope = Scope::default();
        scope.dir("/a/b//");
        scope.dir("/");
        scope.dir("///");
        assert_eq!(scope.params, ["/a/b"]);
        assert_eq!(scope.conditions.len(), 1);
    }

    #[test]
    fn where_clause_parenthesises_each_condition() {
        let mut scope = Scope::default();
        scope.dir("/a");
        scope.equals("agent", "pi");
        assert_eq!(
            scope.where_clause(),
            " WHERE (cwd = ?1 OR substr(cwd, 1, length(?1) + 1) = ?1 || '/') AND (agent = ?2)"
        );
        assert_eq!(Scope::default().where_clause(), "");
    }

    #[test]
    fn visibility_hides_failed_calls_unless_all() {
        let hidden = Scope::visible(&FilterArgs::default());
        assert_eq!(hidden.conditions, ["status != 'failed'"]);
        let all = FilterArgs {
            all: true,
            ..Default::default()
        };
        assert!(Scope::visible(&all).conditions.is_empty());
    }

    #[test]
    fn prefixes_split_on_unicode_whitespace_like_jq() {
        assert_eq!(prefix("  rg\tfoo\n  bar", 2), "rg foo");
        assert_eq!(prefix("a\u{a0}b c", 2), "a b");
        assert_eq!(prefix("a\u{85}b c", 2), "a b");
        assert_eq!(prefix("a\u{b}b c", 2), "a b");
        assert_eq!(prefix("a\u{2003}b c", 2), "a b");
        assert_eq!(prefix("a\u{3000}b c", 2), "a b");
        // Zero-width space is not whitespace for jq either.
        assert_eq!(prefix("a\u{200b}b c", 2), "a\u{200b}b c");
        assert_eq!(prefix("   ", 2), "");
        assert_eq!(prefix("", 1), "");
        assert_eq!(prefix("ls", 3), "ls");
    }

    fn sorted(adds: &[(&str, bool, Newest)]) -> Vec<String> {
        let mut groups = Groups::new(2);
        for (cmd, failed, newest) in adds {
            groups.add(cmd, *failed, *newest);
        }
        groups
            .sorted()
            .into_iter()
            .map(|(p, g)| format!("{}\t{}\t{p}", g.count, g.failed))
            .collect()
    }

    #[test]
    fn groups_by_count_then_recency_then_prefix() {
        let order = sorted(&[
            ("jj log -r @", false, (10, AGENT, 1)),
            ("jj log --no-graph", false, (11, AGENT, 2)),
            ("jj st", false, (12, AGENT, 3)),
            ("nix build .#x", true, (13, AGENT, 4)),
            ("nix build .#y", false, (14, AGENT, 5)),
            ("jj st", true, (16, AGENT, 6)),
            ("ls", false, (17, AGENT, 7)),
            ("pwd", false, (17, AGENT, 8)),
        ]);
        assert_eq!(
            order,
            [
                "2\t1\tjj st",
                "2\t1\tnix build",
                "2\t0\tjj log",
                "1\t0\tpwd",
                "1\t0\tls"
            ]
        );
    }

    #[test]
    fn ties_across_sources_have_one_total_order() {
        // Same count and timestamp: agent records outrank shell entries, then
        // the higher id or later file position, then the prefix.
        let order = sorted(&[
            ("b", false, (5, SHELL, 9)),
            ("a", false, (5, AGENT, 1)),
            ("c", false, (5, AGENT, 2)),
            ("d", false, (5, SHELL, 3)),
        ]);
        assert_eq!(order, ["1\t0\tc", "1\t0\ta", "1\t0\tb", "1\t0\td"]);
        // Order does not depend on insertion order.
        let reversed = sorted(&[
            ("d", false, (5, SHELL, 3)),
            ("c", false, (5, AGENT, 2)),
            ("a", false, (5, AGENT, 1)),
            ("b", false, (5, SHELL, 9)),
        ]);
        assert_eq!(order, reversed);
    }

    #[test]
    fn untimed_entries_fall_outside_any_range() {
        assert!(in_range(None, (None, None)));
        assert!(!in_range(None, (Some(0), None)));
        assert!(in_range(Some(10), (Some(10), Some(11))));
        assert!(!in_range(Some(11), (Some(10), Some(11))));
    }

    fn args(source: Option<Source>, agent: bool, histfile: bool) -> StatsArgs {
        StatsArgs {
            filters: FilterArgs {
                agent: if agent { vec!["pi".into()] } else { vec![] },
                ..Default::default()
            },
            words: 2,
            limit: 30,
            source,
            histfile: histfile.then(|| PathBuf::from("/h")),
            since: None,
            until: None,
        }
    }

    #[test]
    fn source_rules() {
        let ok = |a: StatsArgs| resolve_source(&a).map_err(|f| f.code);
        assert_eq!(ok(args(None, false, false)), Ok(Source::All));
        assert_eq!(ok(args(None, true, false)), Ok(Source::Agents));
        assert_eq!(
            ok(args(Some(Source::Shell), false, true)),
            Ok(Source::Shell)
        );
        assert_eq!(
            ok(args(Some(Source::Agents), true, false)),
            Ok(Source::Agents)
        );
        assert_eq!(ok(args(Some(Source::Shell), true, false)), Err(64));
        assert_eq!(ok(args(Some(Source::All), true, false)), Err(64));
        assert_eq!(ok(args(Some(Source::Agents), false, true)), Err(64));
        assert_eq!(ok(args(None, true, true)), Err(64));
    }
}
