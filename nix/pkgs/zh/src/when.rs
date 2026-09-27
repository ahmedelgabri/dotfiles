//! `--since`/`--until` values. Both bounds are inclusive at the precision
//! given, and become a half-open range `[since, until)` of Unix seconds.

use rusqlite::Connection;

#[derive(Debug, PartialEq)]
enum When {
    /// `YYYY-MM-DD`: a whole local day.
    Day(String),
    /// `YYYY-MM-DD HH:MM`: a whole local minute.
    Minute(String),
    /// `N` hours, days or weeks before now, as fixed 3600/86400/604800 s.
    Ago(i64),
}

fn digits(s: &str, n: usize) -> bool {
    s.len() == n && s.bytes().all(|b| b.is_ascii_digit())
}

fn is_date(s: &str) -> bool {
    let parts: Vec<_> = s.split('-').collect();
    matches!(parts.as_slice(), [y, m, d] if digits(y, 4) && digits(m, 2) && digits(d, 2))
}

fn is_time(s: &str) -> bool {
    match s.split_once(':') {
        Some((h, m)) if digits(h, 2) && digits(m, 2) => {
            h.parse::<u32>().is_ok_and(|h| h < 24) && m.parse::<u32>().is_ok_and(|m| m < 60)
        }
        _ => false,
    }
}

fn parse(value: &str) -> Option<When> {
    if let Some((date, time)) = value.split_once(' ') {
        return (is_date(date) && is_time(time)).then(|| When::Minute(value.to_owned()));
    }
    if is_date(value) {
        return Some(When::Day(value.to_owned()));
    }
    let unit = match value.chars().last()? {
        'h' => 3600,
        'd' => 86_400,
        'w' => 604_800,
        _ => return None,
    };
    let n = &value[..value.len() - 1];
    if n.is_empty() || n.starts_with('0') || !n.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    n.parse::<i64>().ok()?.checked_mul(unit).map(When::Ago)
}

/// The earliest instant whose local time is `minute` ("YYYY-MM-DD HH:MM").
/// SQLite converts local times on its own terms (for a repeated hour it
/// returns the later instant), so its answer is only a starting point:
/// every instant up to two hours either side that maps back to the same
/// local minute is a candidate. None means the minute was skipped by a DST
/// change; several mean it was repeated, and the earliest wins.
fn local_minute(conn: &Connection, minute: &str) -> Result<i64, String> {
    let valid: bool = conn
        .query_row(
            "SELECT strftime('%Y-%m-%d %H:%M', ?1) IS ?1",
            [minute],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;
    if !valid {
        return Err(format!("{minute} is not a valid date and time"));
    }
    let guess: i64 = conn
        .query_row("SELECT unixepoch(?1, 'utc')", [minute], |r| r.get(0))
        .map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT strftime('%Y-%m-%d %H:%M', ?1, 'unixepoch', 'localtime')")
        .map_err(|e| e.to_string())?;
    let mut matches = Vec::new();
    for offset in [-7200, -3600, 0, 3600, 7200] {
        let candidate = guess + offset;
        let local: String = stmt
            .query_row([candidate], |r| r.get(0))
            .map_err(|e| e.to_string())?;
        if local == minute {
            matches.push(candidate);
        }
    }
    matches
        .into_iter()
        .min()
        .ok_or_else(|| format!("{minute} does not exist in local time (skipped by a DST change)"))
}

fn ago(now: i64, seconds: i64) -> Result<i64, String> {
    now.checked_sub(seconds)
        .ok_or_else(|| "time is too far in the past".to_string())
}

fn next_day(conn: &Connection, day: &str) -> Result<String, String> {
    conn.query_row("SELECT date(?1, '+1 day')", [day], |r| r.get(0))
        .map_err(|e| e.to_string())
}

/// Start of the period `value` names, for `--since`.
fn start(conn: &Connection, value: &str, now: i64) -> Result<i64, String> {
    match parse(value).ok_or_else(|| format!("invalid time: {value}"))? {
        When::Day(day) => local_minute(conn, &format!("{day} 00:00")),
        When::Minute(minute) => local_minute(conn, &minute),
        When::Ago(seconds) => ago(now, seconds),
    }
}

/// First second after the period `value` names, for an inclusive `--until`.
fn end(conn: &Connection, value: &str, now: i64) -> Result<i64, String> {
    match parse(value).ok_or_else(|| format!("invalid time: {value}"))? {
        When::Day(day) => {
            local_minute(conn, &format!("{day} 00:00"))?;
            local_minute(conn, &format!("{} 00:00", next_day(conn, &day)?))
        }
        When::Minute(minute) => Ok(local_minute(conn, &minute)? + 60),
        When::Ago(seconds) => Ok(ago(now, seconds)? + 1),
    }
}

/// `[since, until)` in Unix seconds; `None` for an open side. "Now" is read
/// once by the caller so both bounds agree.
pub fn range(
    since: Option<&str>,
    until: Option<&str>,
    now: i64,
) -> Result<(Option<i64>, Option<i64>), String> {
    if since.is_none() && until.is_none() {
        return Ok((None, None));
    }
    let conn = Connection::open_in_memory().map_err(|e| e.to_string())?;
    let since = since.map(|v| start(&conn, v, now)).transpose()?;
    let until = until.map(|v| end(&conn, v, now)).transpose()?;
    if let (Some(s), Some(u)) = (since, until)
        && s >= u
    {
        return Err("--since is after --until".into());
    }
    Ok((since, until))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_the_grammar() {
        assert_eq!(parse("2026-09-30"), Some(When::Day("2026-09-30".into())));
        assert_eq!(
            parse("2026-09-30 18:05"),
            Some(When::Minute("2026-09-30 18:05".into()))
        );
        assert_eq!(parse("12h"), Some(When::Ago(43_200)));
        assert_eq!(parse("2d"), Some(When::Ago(172_800)));
        assert_eq!(parse("1w"), Some(When::Ago(604_800)));
    }

    #[test]
    fn rejects_everything_else() {
        for bad in [
            "",
            "2026-9-30",
            "2026-09-30T18:05",
            "2026-09-30 24:00",
            "2026-09-30 18:60",
            "2026-09-30 8:05",
            "0d",
            "01d",
            "d",
            "2m",
            "-1d",
            "1.5d",
            "2026-09-30  18:05",
            "99999999999999999999d",
            "9223372036854775807w",
        ] {
            assert_eq!(parse(bad), None, "{bad:?}");
        }
    }

    #[test]
    fn rejects_impossible_calendar_dates() {
        let conn = Connection::open_in_memory().unwrap();
        assert!(local_minute(&conn, "2025-02-30 00:00").is_err());
        assert!(local_minute(&conn, "2025-13-01 00:00").is_err());
        assert!(local_minute(&conn, "2024-02-29 00:00").is_ok());
    }

    #[test]
    fn relative_bounds_are_inclusive_instants() {
        let now = 1_000_000;
        assert_eq!(
            range(Some("1h"), Some("1h"), now),
            Ok((Some(996_400), Some(996_401)))
        );
    }

    #[test]
    fn huge_relative_times_fail_instead_of_overflowing() {
        assert!(range(Some("1000000000000000w"), None, i64::MIN / 2).is_err());
    }

    #[test]
    fn reversed_bounds_fail() {
        assert!(range(Some("1h"), Some("2h"), 1_000_000).is_err());
    }
}
