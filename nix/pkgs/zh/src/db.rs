use std::fs::OpenOptions;
use std::io::ErrorKind;
use std::os::unix::fs::OpenOptionsExt;
use std::path::PathBuf;
use std::time::Duration;

use rusqlite::{Connection, TransactionBehavior};

use crate::Fail;

const SCHEMA: &str = "
    CREATE TABLE IF NOT EXISTS commands (
        id INTEGER PRIMARY KEY,
        ts INTEGER NOT NULL,
        agent TEXT NOT NULL,
        cwd TEXT NOT NULL,
        cmd TEXT NOT NULL,
        session TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'ran',
        description TEXT NOT NULL DEFAULT ''
    );
    CREATE INDEX IF NOT EXISTS commands_ts ON commands (ts);
    CREATE INDEX IF NOT EXISTS commands_cwd ON commands (cwd);
    CREATE INDEX IF NOT EXISTS commands_session ON commands (session);
";

pub fn path() -> Result<PathBuf, Fail> {
    let base = std::env::var_os("ZDOTDIR")
        .filter(|dir| !dir.is_empty())
        .or_else(|| std::env::var_os("HOME"))
        .ok_or_else(|| Fail::new("neither ZDOTDIR nor HOME is set"))?;
    Ok(PathBuf::from(base).join(".zh.db"))
}

/// Opens the database for writing, creating it when missing.
pub fn open_or_create() -> Result<(Connection, PathBuf), Fail> {
    let path = path()?;
    // Only the first writer creates the file, private from the start; an
    // existing database keeps its mode. SQLite gives the WAL and shared-memory
    // files the database's mode. Losing the creation race to a concurrent
    // first writer is fine: the file exists either way.
    match OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(0o600)
        .open(&path)
    {
        Ok(_) => {}
        Err(error) if error.kind() == ErrorKind::AlreadyExists => {}
        Err(error) => {
            return Err(Fail::new(format!(
                "could not open {}: {error}",
                path.display()
            )));
        }
    }
    let conn = open(&path)?;
    Ok((conn, path))
}

/// Opens an existing database; `None` when there is none yet, which readers
/// treat as empty rather than creating a file.
pub fn open_existing() -> Result<Option<(Connection, PathBuf)>, Fail> {
    let path = path()?;
    if !path.is_file() {
        return Ok(None);
    }
    let conn = open(&path)?;
    Ok(Some((conn, path)))
}

fn open(path: &PathBuf) -> Result<Connection, Fail> {
    let fail =
        |error: rusqlite::Error| Fail::new(format!("could not open {}: {error}", path.display()));
    let mut conn = Connection::open(path).map_err(fail)?;
    // Before anything that takes a lock: wait up to five seconds for a writer
    // holding the database, then fail.
    conn.busy_timeout(Duration::from_secs(5)).map_err(fail)?;
    create_schema(&mut conn).map_err(fail)?;
    Ok(conn)
}

fn has_table(conn: &Connection) -> rusqlite::Result<bool> {
    conn.query_row(
        "SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'commands')",
        [],
        |row| row.get(0),
    )
}

// Tables from before session, status and description existed are not
// migrated: no database with that schema is in use.
fn create_schema(conn: &mut Connection) -> rusqlite::Result<()> {
    // Checked outside any transaction, so an existing database costs one read
    // and never takes the write lock.
    if has_table(conn)? {
        return Ok(());
    }
    // Switching to WAL returns "database is locked" at once, ignoring the busy
    // timeout, while another process is switching the same file. The process
    // that wins does the switch, and a real write failure still surfaces from
    // the schema creation, so losing that race is not an error.
    let _ = conn.query_row("PRAGMA journal_mode = WAL", [], |_| Ok(()));
    // IMMEDIATE takes the write lock before the first statement, queuing
    // concurrent first writers; IF NOT EXISTS turns the later ones into
    // no-ops. A failure rolls everything back when the transaction drops.
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    tx.execute_batch(SCHEMA)?;
    tx.commit()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn schema(conn: &Connection) -> Vec<(String, String)> {
        let mut stmt = conn
            .prepare("SELECT name, sql FROM sqlite_master ORDER BY name")
            .unwrap();
        stmt.query_map([], |row| Ok((row.get(0)?, row.get(1)?)))
            .unwrap()
            .map(Result::unwrap)
            .collect()
    }

    #[test]
    fn creates_the_full_schema() {
        let mut conn = Connection::open_in_memory().unwrap();
        create_schema(&mut conn).unwrap();
        let names: Vec<_> = schema(&conn).into_iter().map(|(name, _)| name).collect();
        assert_eq!(
            names,
            [
                "commands",
                "commands_cwd",
                "commands_session",
                "commands_ts"
            ]
        );
        let columns: Vec<(String, String, bool, Option<String>)> = conn
            .prepare(
                "SELECT name, type, \"notnull\", dflt_value FROM pragma_table_info('commands')",
            )
            .unwrap()
            .query_map([], |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)))
            .unwrap()
            .map(Result::unwrap)
            .collect();
        let expected = [
            ("id", "INTEGER", false, None),
            ("ts", "INTEGER", true, None),
            ("agent", "TEXT", true, None),
            ("cwd", "TEXT", true, None),
            ("cmd", "TEXT", true, None),
            ("session", "TEXT", true, Some("''")),
            ("status", "TEXT", true, Some("'ran'")),
            ("description", "TEXT", true, Some("''")),
        ];
        let expected: Vec<_> = expected
            .iter()
            .map(|(n, t, nn, d)| (n.to_string(), t.to_string(), *nn, d.map(str::to_string)))
            .collect();
        assert_eq!(columns, expected);
        let index_columns: Vec<(String, String)> = conn
            .prepare(
                "SELECT m.name, i.name FROM sqlite_master AS m, pragma_index_info(m.name) AS i
                 WHERE m.type = 'index' ORDER BY m.name",
            )
            .unwrap()
            .query_map([], |r| Ok((r.get(0)?, r.get(1)?)))
            .unwrap()
            .map(Result::unwrap)
            .collect();
        let expected_indexes = [
            ("commands_cwd", "cwd"),
            ("commands_session", "session"),
            ("commands_ts", "ts"),
        ]
        .map(|(a, b)| (a.to_string(), b.to_string()));
        assert_eq!(index_columns, expected_indexes);
    }

    #[test]
    fn creating_twice_is_a_no_op() {
        let mut conn = Connection::open_in_memory().unwrap();
        create_schema(&mut conn).unwrap();
        conn.execute(
            "INSERT INTO commands (ts, agent, cwd, cmd) VALUES (1, 'a', '/', 'ls')",
            [],
        )
        .unwrap();
        let before = schema(&conn);
        create_schema(&mut conn).unwrap();
        assert_eq!(schema(&conn), before);
        let rows: i64 = conn
            .query_row("SELECT count(*) FROM commands", [], |r| r.get(0))
            .unwrap();
        assert_eq!(rows, 1);
    }

    #[test]
    fn a_failed_creation_leaves_nothing_behind() {
        let mut conn = Connection::open_in_memory().unwrap();
        // An object that shares an index's name makes the last CREATE fail.
        conn.execute_batch("CREATE TABLE commands_session (x)")
            .unwrap();
        assert!(create_schema(&mut conn).is_err());
        let names: Vec<_> = schema(&conn).into_iter().map(|(name, _)| name).collect();
        assert_eq!(names, ["commands_session"]);
    }

    #[test]
    fn leaves_an_existing_table_alone() {
        let mut conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(
            "CREATE TABLE commands (id INTEGER PRIMARY KEY, ts INTEGER NOT NULL,
                agent TEXT NOT NULL, cwd TEXT NOT NULL, cmd TEXT NOT NULL)",
        )
        .unwrap();
        let before = schema(&conn);
        create_schema(&mut conn).unwrap();
        assert_eq!(schema(&conn), before);
    }
}
