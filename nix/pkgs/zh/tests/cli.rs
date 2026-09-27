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
