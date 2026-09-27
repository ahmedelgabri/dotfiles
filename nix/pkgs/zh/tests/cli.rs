//! Runs the built binary against real SQLite databases in temporary
//! directories. Every child gets its own environment; the test process's
//! environment is never changed, so tests can run in parallel.

use std::fs;
use std::io::{Read, Write};
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};
use std::time::{Duration, Instant};

use rusqlite::Connection;
use serde_json::Value;

const BIN: &str = env!("CARGO_BIN_EXE_zh");
const FIXTURES: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures");
const GOLDEN: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/tests/golden");

struct Home {
    _dir: tempfile::TempDir,
    // Canonical, because macOS temp paths go through the /var symlink and
    // jj and git report resolved roots.
    path: PathBuf,
}

impl Home {
    fn new() -> Self {
        let dir = tempfile::tempdir().unwrap();
        let path = fs::canonicalize(dir.path()).unwrap();
        Home { _dir: dir, path }
    }

    fn db(&self) -> PathBuf {
        self.path.join(".zh.db")
    }

    fn command(&self, args: &[&str]) -> Command {
        let mut cmd = Command::new(BIN);
        cmd.args(args)
            .env_clear()
            .env("PATH", std::env::var_os("PATH").unwrap_or_default())
            .env("HOME", &self.path)
            .env("ZDOTDIR", &self.path)
            .env("TZ", "UTC0")
            .env("XDG_CONFIG_HOME", self.path.join(".config"))
            .env("XDG_DATA_HOME", self.path.join(".local/share"))
            .env("JJ_CONFIG", self.path.join("jj.toml"))
            .env("JJ_USER", "Test")
            .env("JJ_EMAIL", "test@example.com")
            .env("GIT_CONFIG_GLOBAL", self.path.join("gitconfig"))
            .env("GIT_CONFIG_NOSYSTEM", "1")
            .stdin(Stdio::null());
        cmd
    }

    fn run(&self, args: &[&str]) -> Output {
        self.command(args).output().unwrap()
    }

    fn record(&self, agent: &str, payload: &str) -> Output {
        let mut child = self
            .command(&["record", agent])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .unwrap();
        child
            .stdin
            .take()
            .unwrap()
            .write_all(payload.as_bytes())
            .unwrap();
        child.wait_with_output().unwrap()
    }

    fn sql(&self, sql: &str) {
        Connection::open(self.db())
            .unwrap()
            .execute_batch(sql)
            .unwrap();
    }

    fn count(&self, sql: &str) -> i64 {
        Connection::open(self.db())
            .unwrap()
            .query_row(sql, [], |r| r.get(0))
            .unwrap()
    }

    fn list(&self, args: &[&str]) -> Vec<String> {
        let mut all = vec!["list"];
        all.extend(args);
        let out = self.run(&all);
        assert!(
            out.status.success(),
            "{}",
            String::from_utf8_lossy(&out.stderr)
        );
        let text = String::from_utf8(out.stdout).unwrap();
        text.split_terminator('\0')
            .map(|row| row.splitn(4, '\t').nth(3).unwrap().to_owned())
            .collect()
    }
}

fn payload(cmd: &str, cwd: &str) -> String {
    serde_json::json!({"cwd": cwd, "tool_input": {"command": cmd}}).to_string()
}

fn stderr(out: &Output) -> String {
    String::from_utf8_lossy(&out.stderr).into_owned()
}

fn mode(path: &Path) -> u32 {
    fs::metadata(path).unwrap().permissions().mode() & 0o777
}

// Golden outputs were produced by the Bash implementation from the same
// fixtures and cases. Successful stdout and the unchanged stderr messages
// must match byte for byte; changed diagnostics are asserted elsewhere.
#[test]
fn matches_the_bash_implementation() {
    let cases: Vec<Value> =
        serde_json::from_str(&fs::read_to_string(format!("{FIXTURES}/cases.json")).unwrap())
            .unwrap();
    for case in cases {
        let name = case["name"].as_str().unwrap();
        let golden: Value =
            serde_json::from_str(&fs::read_to_string(format!("{GOLDEN}/{name}.json")).unwrap())
                .unwrap();
        let home = Home::new();
        let atuin = home.path.join("atuin.db");
        Connection::open(&atuin)
            .unwrap()
            .execute_batch(&fs::read_to_string(format!("{FIXTURES}/atuin.sql")).unwrap())
            .unwrap();
        if case["db"] == "sample" {
            home.sql(&fs::read_to_string(format!("{FIXTURES}/sample.sql")).unwrap());
        }
        let stdin = match case.get("stdin").and_then(Value::as_str) {
            Some("") => Some(String::new()),
            Some(file) => Some(fs::read_to_string(format!("{FIXTURES}/{file}")).unwrap()),
            None => None,
        };
        let atuin_path = atuin.to_str().unwrap();
        for (i, run) in case["runs"].as_array().unwrap().iter().enumerate() {
            let args: Vec<String> = run
                .as_array()
                .unwrap()
                .iter()
                .map(|a| a.as_str().unwrap().replace("{ATUIN}", atuin_path))
                .collect();
            let args: Vec<&str> = args.iter().map(String::as_str).collect();
            let mut cmd = home.command(&args);
            cmd.env("TZ", case["tz"].as_str().unwrap());
            let out = match &stdin {
                Some(input) => {
                    let mut child = cmd
                        .stdin(Stdio::piped())
                        .stdout(Stdio::piped())
                        .stderr(Stdio::piped())
                        .spawn()
                        .unwrap();
                    child
                        .stdin
                        .take()
                        .unwrap()
                        .write_all(input.as_bytes())
                        .unwrap();
                    child.wait_with_output().unwrap()
                }
                None => cmd.output().unwrap(),
            };
            let expected = &golden["runs"][i];
            let context = format!("{name} run {i}");
            assert_eq!(
                out.status.code().map(i64::from),
                expected["code"].as_i64(),
                "{context}: {}",
                stderr(&out)
            );
            let stdout = String::from_utf8(out.stdout.clone())
                .unwrap()
                .replace(atuin_path, "{ATUIN}");
            assert_eq!(
                stdout,
                expected["stdout"].as_str().unwrap(),
                "{context} stdout"
            );
            assert_eq!(
                stderr(&out).replace(atuin_path, "{ATUIN}"),
                expected["stderr"].as_str().unwrap(),
                "{context} stderr"
            );
        }
        if let Some(rows) = golden.get("rows") {
            let conn = Connection::open(home.db()).unwrap();
            let mut stmt = conn
                .prepare("SELECT agent, cwd, cmd, session, status, description FROM commands ORDER BY id")
                .unwrap();
            let actual: Vec<Value> = stmt
                .query_map([], |r| {
                    Ok(Value::from(
                        (0..6)
                            .map(|i| r.get::<_, String>(i))
                            .collect::<Result<Vec<_>, _>>()?,
                    ))
                })
                .unwrap()
                .map(Result::unwrap)
                .collect();
            assert_eq!(&Value::from(actual), rows, "{name} rows");
        } else if case.get("rows") == Some(&Value::Bool(true)) {
            assert!(!home.db().exists(), "{name}: no database expected");
        }
    }
}

// The approved error contract: exit codes as before, clap's own messages.
#[test]
fn argument_errors_keep_their_exit_codes() {
    let home = Home::new();
    let cases: &[(&[&str], i32)] = &[
        (&[], 64),
        (&["--bogus"], 64),
        (&["bogus"], 64),
        (&["list", "--bad"], 1),
        (&["list", "--dir"], 1),
        (&["list", "--", "x"], 1),
        (&["show", "x"], 1),
        (&["show"], 1),
        (&["forget"], 1),
        (&["forget", "a", "b"], 1),
        (&["forget", "--weird", "cmd"], 1),
        (&["forget", "--weird cmd"], 1),
        (&["forget", "-x"], 1),
        (&["forget", "--"], 1),
        (&["record"], 1),
        (&["stats", "--bogus"], 1),
        (&["stats", "--words"], 64),
        (&["stats", "--words", "0"], 64),
        (&["stats", "--words", "-1"], 64),
        (&["stats", "--words", "--help"], 64),
        (&["stats", "--limit", "--all"], 64),
        (&["stats", "--limit", "x"], 64),
    ];
    for (args, code) in cases {
        let out = home.run(args);
        assert_eq!(out.status.code(), Some(*code), "{args:?}");
        assert!(!out.stderr.is_empty(), "{args:?} explains itself");
        assert!(out.stdout.is_empty(), "{args:?}");
    }
}

#[test]
fn help_prints_and_succeeds() {
    let home = Home::new();
    for args in [
        &["--help"][..],
        &["-h"],
        &["list", "--help"],
        &["stats", "-h"],
        &["show", "--help"],
        &["forget", "--help"],
    ] {
        let out = home.run(args);
        assert_eq!(out.status.code(), Some(0), "{args:?}");
        assert!(
            String::from_utf8_lossy(&out.stdout).contains("Usage"),
            "{args:?}"
        );
    }
}

#[test]
fn forget_and_show_take_hyphenated_commands_after_the_separator() {
    let home = Home::new();
    let commands = ["--", "--help", "--weird cmd", "-x", "keep"];
    for cmd in commands {
        home.record("claude", &payload(cmd, "/r"));
    }
    let out = home.run(&["show", "--", "--help"]);
    assert!(String::from_utf8_lossy(&out.stdout).ends_with("\n--help\n"));

    // Help, not a deletion.
    let out = home.run(&["forget", "--help"]);
    assert_eq!(out.status.code(), Some(0));
    assert!(String::from_utf8_lossy(&out.stdout).contains("Usage"));
    assert_eq!(
        home.count("SELECT count(*) FROM commands WHERE cmd = '--help'"),
        1
    );

    let mut left = commands.len() as i64;
    for cmd in ["--", "--help", "--weird cmd", "-x"] {
        let out = home.run(&["forget", "--", cmd]);
        assert_eq!(out.status.code(), Some(0), "{cmd}: {}", stderr(&out));
        assert_eq!(stderr(&out), "zh: forgot 1 records\n", "{cmd}");
        left -= 1;
        assert_eq!(home.count("SELECT count(*) FROM commands"), left, "{cmd}");
    }
    assert_eq!(home.list(&[]), ["keep"]);
}
#[test]
fn creates_a_private_database_and_keeps_an_existing_mode() {
    let home = Home::new();
    home.record("claude", &payload("ls", "/"));
    assert_eq!(mode(&home.db()), 0o600);
    // Hold a connection so the WAL and shared-memory files stay around.
    let conn = Connection::open(home.db()).unwrap();
    conn.query_row("SELECT count(*) FROM commands", [], |r| r.get::<_, i64>(0))
        .unwrap();
    home.record("claude", &payload("pwd", "/"));
    for suffix in ["-wal", "-shm"] {
        let path = PathBuf::from(format!("{}{suffix}", home.db().display()));
        assert_eq!(mode(&path), 0o600, "{suffix}");
    }
    drop(conn);

    let other = Home::new();
    fs::write(other.db(), b"").unwrap();
    fs::set_permissions(other.db(), fs::Permissions::from_mode(0o644)).unwrap();
    let out = other.record("claude", &payload("ls", "/"));
    assert!(out.status.success(), "{}", stderr(&out));
    assert_eq!(other.list(&[]), ["ls"]);
    assert_eq!(mode(&other.db()), 0o644);
}

#[test]
fn empty_zdotdir_falls_back_to_home() {
    let home = Home::new();
    let mut cmd = home.command(&["record", "claude"]);
    cmd.env("ZDOTDIR", "").env("HOME", home.path.join("h"));
    fs::create_dir(home.path.join("h")).unwrap();
    let mut child = cmd.stdin(Stdio::piped()).spawn().unwrap();
    child
        .stdin
        .take()
        .unwrap()
        .write_all(payload("ls", "/").as_bytes())
        .unwrap();
    assert!(child.wait().unwrap().success());
    assert!(home.path.join("h/.zh.db").exists());
}

#[test]
fn a_malformed_tail_records_nothing() {
    let home = Home::new();
    let out = home.record("claude", &format!("{} {{", payload("ls", "/")));
    assert_eq!(out.status.code(), Some(1));
    assert!(stderr(&out).contains("could not parse hook payload"));
    assert!(!home.db().exists());
}

#[test]
fn odd_payloads_are_normalised() {
    let home = Home::new();
    let out = home.record(
        "claude",
        r#"{"cwd":5,"tool_input":{"command":"a\u0000b","description":7}} {"tool_input":"ls"}"#,
    );
    assert!(out.status.success(), "{}", stderr(&out));
    assert_eq!(home.list(&[]), ["ab"]);
    assert_eq!(
        home.count("SELECT count(*) FROM commands WHERE cwd = '' AND description = ''"),
        1
    );
}

#[test]
fn simultaneous_first_writers_all_succeed() {
    for round in 0..10 {
        for precreated in [false, true] {
            let home = Home::new();
            if precreated {
                // A creator that lost the race before SQLite wrote a header.
                fs::write(home.db(), b"").unwrap();
            }
            // Every child is waiting on stdin before any payload goes out, so
            // they reach the database together instead of one per spawn.
            let mut children: Vec<_> = (0..8)
                .map(|_| {
                    home.command(&["record", "claude"])
                        .stdin(Stdio::piped())
                        .stdout(Stdio::piped())
                        .stderr(Stdio::piped())
                        .spawn()
                        .unwrap()
                })
                .collect();
            let inputs: Vec<_> = children
                .iter_mut()
                .map(|c| c.stdin.take().unwrap())
                .collect();
            for (i, mut input) in inputs.into_iter().enumerate() {
                input
                    .write_all(payload(&format!("c{i}"), "/").as_bytes())
                    .unwrap();
            }
            for child in children {
                let out = child.wait_with_output().unwrap();
                assert!(
                    out.status.success(),
                    "round {round} precreated={precreated}: {}",
                    stderr(&out)
                );
                assert!(out.stderr.is_empty(), "round {round}: {}", stderr(&out));
            }
            assert_eq!(home.count("SELECT count(*) FROM commands"), 8);
            assert_eq!(
                home.count("SELECT count(*) FROM sqlite_master WHERE type = 'index'"),
                3
            );
        }
    }
}

#[test]
fn reads_during_a_write_transaction_without_touching_the_journal() {
    let home = Home::new();
    home.record("claude", &payload("ls", "/"));
    let conn = Connection::open(home.db()).unwrap();
    conn.execute_batch("BEGIN IMMEDIATE; INSERT INTO commands (ts, agent, cwd, cmd) VALUES (2, 'x', '/', 'uncommitted');")
        .unwrap();
    assert_eq!(home.list(&[]), ["ls"]);
    conn.execute_batch("ROLLBACK").unwrap();

    // A full-schema database in rollback-journal mode stays in that mode, and
    // a reader does not wait for the writer's lock.
    let other = Home::new();
    let sample = fs::read_to_string(format!("{FIXTURES}/sample.sql")).unwrap();
    other.sql(&sample);
    let journal = || -> String {
        Connection::open(other.db())
            .unwrap()
            .query_row("PRAGMA journal_mode", [], |r| r.get(0))
            .unwrap()
    };
    assert_eq!(journal(), "delete");
    let writer = Connection::open(other.db()).unwrap();
    writer.execute_batch("BEGIN IMMEDIATE").unwrap();
    let start = Instant::now();
    assert!(!other.list(&[]).is_empty());
    assert!(start.elapsed() < Duration::from_secs(2));
    writer.execute_batch("ROLLBACK").unwrap();
    assert_eq!(journal(), "delete");
}
#[test]
fn a_lock_held_past_the_timeout_fails_with_context() {
    let home = Home::new();
    home.record("claude", &payload("ls", "/"));
    let conn = Connection::open(home.db()).unwrap();
    conn.execute_batch("BEGIN IMMEDIATE").unwrap();
    let start = Instant::now();
    let out = home.record("claude", &payload("pwd", "/"));
    assert!(start.elapsed() >= Duration::from_secs(5));
    assert_eq!(out.status.code(), Some(1));
    assert!(
        stderr(&out).starts_with("zh: could not write "),
        "{}",
        stderr(&out)
    );
    conn.execute_batch("ROLLBACK").unwrap();
}

#[test]
fn an_older_schema_is_rejected_unchanged() {
    let home = Home::new();
    home.sql(
        "CREATE TABLE commands (id INTEGER PRIMARY KEY, ts INTEGER NOT NULL,
            agent TEXT NOT NULL, cwd TEXT NOT NULL, cmd TEXT NOT NULL);
         INSERT INTO commands (ts, agent, cwd, cmd) VALUES (1, 'claude', '/old', 'old cmd');",
    );
    let before = home.count("SELECT count(*) FROM pragma_table_info('commands')");
    let out = home.record("claude", &payload("ls", "/"));
    assert_eq!(out.status.code(), Some(1));
    assert!(
        stderr(&out).starts_with("zh: could not write ") && stderr(&out).contains("session"),
        "{}",
        stderr(&out)
    );
    assert_eq!(before, 5);
    assert_eq!(
        home.count("SELECT count(*) FROM pragma_table_info('commands')"),
        5
    );
    assert_eq!(home.count("SELECT count(*) FROM commands"), 1);
    assert_eq!(
        home.count("SELECT count(*) FROM sqlite_master WHERE type = 'index'"),
        0
    );
}
#[test]
fn corrupt_and_unwritable_databases_fail_with_context() {
    let home = Home::new();
    fs::write(home.db(), vec![b'x'; 4096]).unwrap();
    for out in [
        home.record("claude", &payload("ls", "/")),
        home.run(&["list"]),
    ] {
        assert_eq!(out.status.code(), Some(1));
        assert!(
            stderr(&out).starts_with("zh: could not open "),
            "{}",
            stderr(&out)
        );
    }

    let home = Home::new();
    home.record("claude", &payload("ls", "/"));
    fs::set_permissions(home.db(), fs::Permissions::from_mode(0o400)).unwrap();
    let out = home.record("claude", &payload("pwd", "/"));
    assert_eq!(out.status.code(), Some(1));
    assert!(
        stderr(&out).starts_with("zh: could not "),
        "{}",
        stderr(&out)
    );
    assert_eq!(home.list(&[]), ["ls"]);
}

#[test]
fn forget_scrubs_when_quiet_and_succeeds_beside_a_reader() {
    let home = Home::new();
    let marker = "UNIQUE-MARKER-4f1d9c";
    home.record("claude", &payload(&format!("echo {marker}"), "/"));
    home.record("claude", &payload("keep", "/"));
    let out = home.run(&["forget", &format!("echo {marker}")]);
    assert_eq!(stderr(&out), "zh: forgot 1 records\n");
    for suffix in ["", "-wal"] {
        if let Ok(bytes) = fs::read(format!("{}{suffix}", home.db().display())) {
            assert!(
                !bytes.windows(marker.len()).any(|w| w == marker.as_bytes()),
                "{suffix}"
            );
        }
    }

    home.record("claude", &payload("drop me", "/"));
    let reader = Connection::open(home.db()).unwrap();
    reader.execute_batch("BEGIN").unwrap();
    reader
        .query_row("SELECT count(*) FROM commands", [], |r| r.get::<_, i64>(0))
        .unwrap();
    let out = home.run(&["forget", "drop me"]);
    assert_eq!(out.status.code(), Some(0), "{}", stderr(&out));
    assert_eq!(stderr(&out), "zh: forgot 1 records\n");
    reader.execute_batch("COMMIT").unwrap();
    assert_eq!(home.list(&[]), ["keep"]);
}

#[test]
fn a_closed_pipe_ends_quietly() {
    let home = Home::new();
    let conn = Connection::open(home.db()).unwrap();
    drop(conn);
    home.record("claude", &payload("seed", "/"));
    home.sql(
        "WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 20000)
         INSERT INTO commands (ts, agent, cwd, cmd) SELECT i, 'claude', '/', 'command number ' || i FROM n;",
    );
    let mut child = home
        .command(&["list"])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .unwrap();
    let mut stdout = child.stdout.take().unwrap();
    let mut first = [0u8; 16];
    stdout.read_exact(&mut first).unwrap();
    drop(stdout);
    let out = child.wait_with_output().unwrap();
    assert_eq!(out.status.code(), Some(0));
    assert!(out.stderr.is_empty(), "{}", stderr(&out));
}

fn run_in(dir: &Path, home: &Home, program: &str, args: &[&str]) {
    let status = Command::new(program)
        .args(args)
        .current_dir(dir)
        .env_clear()
        .env("PATH", std::env::var_os("PATH").unwrap_or_default())
        .env("HOME", &home.path)
        .env("JJ_CONFIG", home.path.join("jj.toml"))
        .env("JJ_USER", "Test")
        .env("JJ_EMAIL", "test@example.com")
        .env("GIT_CONFIG_GLOBAL", home.path.join("gitconfig"))
        .env("GIT_CONFIG_NOSYSTEM", "1")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .unwrap();
    assert!(status.success(), "{program} {args:?}");
}

#[test]
fn repo_filters_cover_the_whole_checkout() {
    let home = Home::new();
    let jj = home.path.join("jj repo");
    let git = home.path.join("git repo");
    let plain = home.path.join("plain");
    for dir in [jj.join("sub/deep"), git.join("sub"), plain.join("sub")] {
        fs::create_dir_all(dir).unwrap();
    }
    run_in(&jj, &home, "jj", &["git", "init"]);
    run_in(&git, &home, "git", &["init", "-q"]);
    let at = |p: &Path| p.to_str().unwrap().to_owned();
    for (cmd, dir) in [
        ("jj-root", at(&jj)),
        ("jj-deep", at(&jj.join("sub/deep"))),
        ("git-root", at(&git)),
        ("git-sub", at(&git.join("sub"))),
        ("plain", at(&plain)),
        ("plain-sub", at(&plain.join("sub"))),
    ] {
        home.record("claude", &payload(cmd, &dir));
    }
    let sorted = |mut v: Vec<String>| {
        v.sort();
        v
    };
    assert_eq!(
        sorted(home.list(&["--repo", &at(&jj.join("sub/deep"))])),
        ["jj-deep", "jj-root"]
    );
    assert_eq!(
        sorted(home.list(&["--repo", &at(&git.join("sub"))])),
        ["git-root", "git-sub"]
    );
    assert_eq!(
        home.list(&["--repo", &at(&plain.join("sub"))]),
        ["plain-sub"]
    );
    assert_eq!(
        sorted(home.list(&["--repo", &at(&git.join("sub")), "--dir", &at(&git)])),
        ["git-root", "git-sub"]
    );
    assert!(
        home.list(&["--repo", &at(&git), "--dir", &at(&jj)])
            .is_empty()
    );
}

#[test]
fn import_reports_missing_sources() {
    let home = Home::new();
    let out = home.run(&["import-atuin", "/no/such/atuin.db"]);
    assert_eq!(out.status.code(), Some(1));
    assert_eq!(stderr(&out), "zh: no atuin database at /no/such/atuin.db\n");
    let out = home.run(&["import-atuin"]);
    assert_eq!(out.status.code(), Some(1));
    assert!(stderr(&out).contains(".local/share/atuin/history.db"));
}

/// A history file in zsh's EXTENDED_HISTORY format; `None` writes a plain
/// line without a timestamp.
fn history(entries: &[(Option<i64>, &str)]) -> String {
    entries
        .iter()
        .map(|(ts, cmd)| match ts {
            Some(ts) => format!(": {ts}:0;{cmd}\n"),
            None => format!("{cmd}\n"),
        })
        .collect()
}

impl Home {
    fn stats(&self, tz: &str, args: &[&str]) -> Output {
        let mut all = vec!["stats"];
        all.extend(args);
        let mut cmd = self.command(&all);
        cmd.env("TZ", tz);
        cmd.output().unwrap()
    }

    fn stats_lines(&self, tz: &str, args: &[&str]) -> Vec<String> {
        let out = self.stats(tz, args);
        assert!(out.status.success(), "{args:?}: {}", stderr(&out));
        String::from_utf8(out.stdout)
            .unwrap()
            .lines()
            .map(str::to_owned)
            .collect()
    }
}

#[test]
fn stats_counts_shell_history_and_agent_records() {
    let home = Home::new();
    fs::write(
        home.path.join(".zsh_history"),
        history(&[
            (Some(100), "git status"),
            (Some(101), "git status"),
            (Some(102), "ls"),
        ]),
    )
    .unwrap();
    home.record("claude", &payload("git status", "/"));
    home.record("claude", &payload("cargo test", "/"));
    assert_eq!(
        home.stats_lines("UTC0", &["--words", "2"]),
        ["3\t0\tgit status", "1\t0\tcargo test", "1\t0\tls"]
    );
    assert_eq!(
        home.stats_lines("UTC0", &["--source", "shell"]),
        ["2\t0\tgit status", "1\t0\tls"]
    );
    assert_eq!(
        home.stats_lines("UTC0", &["--source", "agents"]),
        ["1\t0\tcargo test", "1\t0\tgit status"]
    );
    // An agent-only filter selects agents by itself.
    assert_eq!(home.stats_lines("UTC0", &["--agent", "claude"]).len(), 2);
    // --all keeps its meaning for stats: none.
    assert_eq!(
        home.stats_lines("UTC0", &["--all", "--source", "shell"])
            .len(),
        2
    );
}

#[test]
fn stats_reads_an_explicit_history_file_and_skips_secrets() {
    let home = Home::new();
    let file = home.path.join("other_history");
    fs::write(
        &file,
        history(&[
            (Some(1), "export GITHUB_TOKEN=abc"),
            (Some(2), "git clone https://me:hunter2@example.com/r"),
            (Some(3), "make"),
        ]),
    )
    .unwrap();
    assert_eq!(
        home.stats_lines(
            "UTC0",
            &["--source", "shell", "--histfile", file.to_str().unwrap()]
        ),
        ["1\t0\tmake"]
    );
}

#[test]
fn each_source_is_read_only_when_selected() {
    // Shell only: no database, then a corrupt one, makes no difference.
    let home = Home::new();
    fs::write(home.path.join(".zsh_history"), history(&[(Some(1), "ls")])).unwrap();
    assert_eq!(
        home.stats_lines("UTC0", &["--source", "shell"]),
        ["1\t0\tls"]
    );
    fs::write(home.db(), vec![b'x'; 4096]).unwrap();
    assert_eq!(
        home.stats_lines("UTC0", &["--source", "shell"]),
        ["1\t0\tls"]
    );
    let out = home.stats("UTC0", &[]);
    assert_eq!(out.status.code(), Some(1));

    // Agents only: an unreadable history file makes no difference; a missing
    // one is an empty source; an unreadable one fails when it is read.
    let home = Home::new();
    home.record("claude", &payload("ls", "/"));
    assert_eq!(home.stats_lines("UTC0", &[]), ["1\t0\tls"]);
    let hist = home.path.join(".zsh_history");
    fs::write(&hist, history(&[(Some(1), "pwd")])).unwrap();
    fs::set_permissions(&hist, fs::Permissions::from_mode(0o000)).unwrap();
    assert_eq!(
        home.stats_lines("UTC0", &["--source", "agents"]),
        ["1\t0\tls"]
    );
    let out = home.stats("UTC0", &["--source", "shell"]);
    assert_eq!(out.status.code(), Some(1));
    assert!(
        stderr(&out).starts_with("zh: could not read "),
        "{}",
        stderr(&out)
    );
    fs::set_permissions(&hist, fs::Permissions::from_mode(0o600)).unwrap();
}

#[test]
fn stats_source_and_time_usage_errors_exit_64() {
    let home = Home::new();
    for args in [
        &["--agent", "pi", "--source", "shell"][..],
        &["--dir", "/", "--source", "all"],
        &["--histfile", "/h", "--source", "agents"],
        &["--histfile", "/h", "--session", "s"],
        &["--source", "bogus"],
        &["--source"],
        &["--since"],
        &["--until"],
        &["--since", "2026-02-30"],
        &["--since", "2026-09-30 24:00"],
        &["--since", "yesterday"],
        &["--since", "-1d"],
        &["--since", "2d", "--until", "3d"],
        &["--since", "99999999999999999w"],
    ] {
        let out = home.stats("UTC0", args);
        assert_eq!(out.status.code(), Some(64), "{args:?}: {}", stderr(&out));
        assert!(!out.stderr.is_empty());
    }
}

#[test]
fn time_bounds_are_inclusive_at_their_precision() {
    let home = Home::new();
    fs::write(
        home.path.join(".zsh_history"),
        history(&[
            (Some(1788220799), "aug31-last-second"),
            (Some(1788220800), "sep01-first-second"),
            (Some(1790791500), "sep30-1805-start"),
            (Some(1790791559), "sep30-1805-end"),
            (Some(1790791560), "sep30-1806"),
            (Some(1790812799), "sep30-last-second"),
            (Some(1790812800), "oct01-first-second"),
            (None, "untimed"),
        ]),
    )
    .unwrap();
    let names = |args: &[&str]| -> Vec<String> {
        let mut all = vec!["--source", "shell", "--words", "1"];
        all.extend(args);
        let mut v: Vec<String> = home
            .stats_lines("UTC0", &all)
            .into_iter()
            .map(|l| l.rsplit('\t').next().unwrap().to_owned())
            .collect();
        v.sort();
        v
    };
    assert_eq!(
        names(&["--since", "2026-09-01", "--until", "2026-09-30"]),
        [
            "sep01-first-second",
            "sep30-1805-end",
            "sep30-1805-start",
            "sep30-1806",
            "sep30-last-second"
        ]
    );
    assert_eq!(
        names(&["--since", "2026-09-30 18:05", "--until", "2026-09-30 18:05"]),
        ["sep30-1805-end", "sep30-1805-start"]
    );
    assert_eq!(names(&["--since", "2026-10-01"]), ["oct01-first-second"]);
    assert!(names(&[]).contains(&"untimed".to_owned()));
    assert!(!names(&["--until", "2026-12-31"]).contains(&"untimed".to_owned()));
}

#[test]
fn relative_bounds_count_back_from_now() {
    let home = Home::new();
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64;
    fs::write(
        home.path.join(".zsh_history"),
        history(&[(Some(now - 3 * 3600), "old"), (Some(now - 3600), "recent")]),
    )
    .unwrap();
    home.record("claude", &payload("agent-now", "/"));
    home.sql(&format!(
        "INSERT INTO commands (ts, agent, cwd, cmd) VALUES ({}, 'pi', '/', 'agent-old')",
        now - 10 * 86400
    ));
    let lines = home.stats_lines("UTC0", &["--since", "2h", "--words", "1"]);
    let mut names: Vec<_> = lines
        .iter()
        .map(|l| l.rsplit('\t').next().unwrap())
        .collect();
    names.sort();
    assert_eq!(names, ["agent-now", "recent"]);
    let lines = home.stats_lines("UTC0", &["--until", "1w", "--words", "1"]);
    assert_eq!(lines, ["1\t0\tagent-old"]);
}

#[test]
fn dst_times_resolve_explicitly() {
    let home = Home::new();
    fs::write(
        home.path.join(".zsh_history"),
        history(&[
            (Some(1792889100), "berlin-0045z"),
            (Some(1793511900), "newyork-0545z"),
        ]),
    )
    .unwrap();
    let berlin = "CET-1CEST,M3.5.0,M10.5.0/3";
    let new_york = "EST5EDT,M3.2.0,M11.1.0";
    // 02:30 happens twice in Berlin on 2026-10-25 (00:30Z and 01:30Z); the
    // earlier one is used, so an entry at 00:45Z is after it.
    let out = home.stats_lines(
        berlin,
        &[
            "--source",
            "shell",
            "--since",
            "2026-10-25 02:30",
            "--until",
            "2026-10-25",
        ],
    );
    assert_eq!(out, ["1\t0\tberlin-0045z"]);
    // 01:30 happens twice in New York on 2026-11-01 (05:30Z and 06:30Z).
    let out = home.stats_lines(
        new_york,
        &[
            "--source",
            "shell",
            "--since",
            "2026-11-01 01:30",
            "--until",
            "2026-11-01",
        ],
    );
    assert_eq!(out, ["1\t0\tnewyork-0545z"]);
    // Skipped hours do not exist.
    for (tz, when) in [(berlin, "2026-03-29 02:30"), (new_york, "2026-03-08 02:30")] {
        let out = home.stats(tz, &["--source", "shell", "--since", when]);
        assert_eq!(out.status.code(), Some(64), "{tz} {when}");
        assert!(stderr(&out).contains("does not exist"), "{}", stderr(&out));
    }
}

#[test]
fn a_tab_in_the_directory_does_not_shift_the_command() {
    let home = Home::new();
    home.record("claude", &payload("echo real\twith tab", "/tmp/a\tb"));
    let out = home.run(&["list"]);
    let row = String::from_utf8(out.stdout).unwrap();
    let fields: Vec<&str> = row.trim_end_matches('\0').splitn(4, '\t').collect();
    assert_eq!(fields[2], "/tmp/a\u{2409}b");
    assert_eq!(fields[3], "echo real\twith tab");
    // The stored directory is unchanged; only the listing shows the symbol.
    assert_eq!(
        home.count("SELECT count(*) FROM commands WHERE cwd = '/tmp/a' || char(9) || 'b'"),
        1
    );
}
