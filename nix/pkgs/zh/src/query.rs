use std::cmp::Reverse;
use std::collections::HashMap;
use std::io::{self, BufWriter, ErrorKind, Write};
use std::path::PathBuf;

use rusqlite::{Connection, params_from_iter};

use crate::{Fail, FilterArgs, db, repo};

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

#[derive(Debug, PartialEq)]
struct Group {
    count: usize,
    failed: usize,
    newest: (i64, i64),
}

/// First `words` whitespace-separated words joined by one space. The iterator
/// stops after them, so long heredocs cost nothing.
fn prefix(cmd: &str, words: usize) -> String {
    cmd.split_whitespace()
        .take(words)
        .collect::<Vec<_>>()
        .join(" ")
}

fn group(
    rows: impl IntoIterator<Item = (i64, i64, String, String)>,
    words: usize,
) -> Vec<(String, Group)> {
    let mut groups: HashMap<String, Group> = HashMap::new();
    for (id, ts, status, cmd) in rows {
        let group = groups.entry(prefix(&cmd, words)).or_insert(Group {
            count: 0,
            failed: 0,
            newest: (ts, id),
        });
        group.count += 1;
        group.failed += usize::from(status == "failed");
        group.newest = group.newest.max((ts, id));
    }
    let mut groups: Vec<_> = groups.into_iter().collect();
    // Most used first; ties go to the most recently used, then by prefix, so
    // the order is deterministic.
    groups.sort_by(|(a_prefix, a), (b_prefix, b)| {
        (Reverse(a.count), Reverse(a.newest), a_prefix).cmp(&(
            Reverse(b.count),
            Reverse(b.newest),
            b_prefix,
        ))
    });
    groups
}

/// Groups every record in scope, failed ones included, by the first N words
/// of its command. Words are whitespace runs, not shell syntax, so an env
/// prefix or `cd x &&` counts as words. The failed column counts calls Claude
/// reported through PostToolUseFailure: worth a look, not a list of denials.
pub fn stats(filters: &FilterArgs, words: usize, limit: usize) -> Result<(), Fail> {
    let Some((conn, path)) = db::open_existing()? else {
        return Ok(());
    };
    let scope = Scope::from_filters(filters);
    let sql = format!(
        "SELECT id, ts, status, cmd FROM commands{}",
        scope.where_clause()
    );
    let fail = read_fail(&path);
    let mut stmt = conn.prepare(&sql).map_err(&fail)?;
    let rows = stmt
        .query_map(params_from_iter(&scope.params), |row| {
            Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?))
        })
        .map_err(&fail)?
        .collect::<rusqlite::Result<Vec<_>>>()
        .map_err(&fail)?;
    let groups = group(rows, words);
    emit(|out| {
        for (prefix, group) in groups.iter().take(limit) {
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

    #[test]
    fn groups_by_count_then_recency_then_prefix() {
        let rows = [
            (1, 10, "ran", "jj log -r @"),
            (2, 11, "ran", "jj log --no-graph"),
            (3, 12, "ran", "jj st"),
            (4, 13, "failed", "nix build .#x"),
            (5, 14, "ran", "nix build .#y"),
            (6, 16, "failed", "jj st"),
            (7, 17, "ran", "ls"),
            (8, 17, "ran", "pwd"),
        ]
        .map(|(id, ts, status, cmd)| (id, ts, status.to_string(), cmd.to_string()));
        let order: Vec<_> = group(rows, 2)
            .into_iter()
            .map(|(p, g)| format!("{}\t{}\t{p}", g.count, g.failed))
            .collect();
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
}
