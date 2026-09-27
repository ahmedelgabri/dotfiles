//! Reads a zsh history file the way zsh's own reader does, so every entry
//! comes back as the command that was typed.

/// One history entry. `ts` is the start time from an EXTENDED_HISTORY header;
/// entries written without that option have none.
#[derive(Debug, PartialEq)]
pub struct Entry {
    pub ts: Option<i64>,
    pub cmd: String,
}

const META: u8 = 0x83;

/// zsh stores bytes that clash with its internal tokens as 0x83 followed by
/// the byte XOR 0x20. A 0x83 with nothing after it is dropped.
fn unmetafy(bytes: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(bytes.len());
    let mut iter = bytes.iter();
    while let Some(&b) = iter.next() {
        if b == META {
            if let Some(&next) = iter.next() {
                out.push(next ^ 0x20);
            }
        } else {
            out.push(b);
        }
    }
    out
}

/// `: <start>:<elapsed>;<command>`
fn split_header(record: &str) -> Option<(i64, &str)> {
    let rest = record.strip_prefix(": ")?;
    let (start, rest) = rest.split_once(':')?;
    let (elapsed, cmd) = rest.split_once(';')?;
    let all_digits = |s: &str| !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit());
    if !all_digits(start) || !all_digits(elapsed) {
        return None;
    }
    Some((start.parse().ok()?, cmd))
}

/// zsh writes a command that really ends in a backslash (optionally followed
/// by spaces) with one extra space, so the backslash is not read as a line
/// continuation; its reader takes that one space off again.
fn unprotect_trailing_backslash(cmd: &mut String) {
    let trimmed = cmd.trim_end_matches(' ');
    if trimmed.ends_with('\\') && trimmed.len() < cmd.len() {
        cmd.pop();
    }
}

fn entry(record: String) -> Option<Entry> {
    let (ts, mut cmd) = match split_header(&record) {
        Some((ts, cmd)) => (Some(ts), cmd.to_owned()),
        // Without EXTENDED_HISTORY zsh escapes a leading colon so the entry
        // cannot be mistaken for a header.
        None => (
            None,
            record
                .strip_prefix("\\:")
                .map_or(record.clone(), |rest| format!(":{rest}")),
        ),
    };
    unprotect_trailing_backslash(&mut cmd);
    if cmd.is_empty() {
        return None;
    }
    Some(Entry { ts, cmd })
}

/// Calls `f` with each entry in file order. Logical records are assembled
/// before headers are recognised: a line ending in a backslash continues on
/// the next line (the backslash dropped, the newline kept), so a continuation
/// line that looks like a header is part of the command. An incomplete final
/// record, where the file ends inside a continuation, is kept as far as it
/// goes.
pub fn for_each_entry(bytes: &[u8], mut f: impl FnMut(Entry)) {
    let text = String::from_utf8_lossy(&unmetafy(bytes)).into_owned();
    let mut record = String::new();
    let mut continuing = false;
    for line in text.split('\n') {
        match line.strip_suffix('\\') {
            Some(head) => {
                record.push_str(head);
                record.push('\n');
                continuing = true;
            }
            None => {
                record.push_str(line);
                continuing = false;
                if let Some(e) = entry(std::mem::take(&mut record)) {
                    f(e);
                }
            }
        }
    }
    if continuing {
        record.pop();
        if let Some(e) = entry(record) {
            f(e);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entries(bytes: &[u8]) -> Vec<Entry> {
        let mut all = Vec::new();
        for_each_entry(bytes, |e| all.push(e));
        all
    }

    fn e(ts: Option<i64>, cmd: &str) -> Entry {
        Entry {
            ts,
            cmd: cmd.into(),
        }
    }

    #[test]
    fn reads_extended_entries() {
        assert_eq!(
            entries(b": 100:0;ls -la\n: 101:3;git status\n"),
            [e(Some(100), "ls -la"), e(Some(101), "git status")]
        );
    }

    #[test]
    fn joins_continuation_lines_before_reading_headers() {
        let file = b": 100:0;echo one \\\n: 200:0;not a header\\\ntail\n: 300:0;next\n";
        assert_eq!(
            entries(file),
            [
                e(Some(100), "echo one \n: 200:0;not a header\ntail"),
                e(Some(300), "next")
            ]
        );
    }

    #[test]
    fn a_protected_trailing_backslash_loses_one_space() {
        assert_eq!(entries(b": 1:0;echo \\ \n"), [e(Some(1), "echo \\")]);
        assert_eq!(entries(b": 1:0;echo \\   \n"), [e(Some(1), "echo \\  ")]);
        // No backslash: spaces are the command's own.
        assert_eq!(entries(b": 1:0;echo x  \n"), [e(Some(1), "echo x  ")]);
    }

    #[test]
    fn reads_plain_entries_and_unescapes_a_leading_colon() {
        assert_eq!(
            entries(b"ls\n\\: not a header\n: also not\n"),
            [
                e(None, "ls"),
                e(None, ": not a header"),
                e(None, ": also not")
            ]
        );
    }

    #[test]
    fn unmetafies_bytes() {
        // "é" is C3 A9; zsh metafies A9 ^ 0x20 = 89 as 83 89.
        assert_eq!(entries(b": 1:0;ol\xc3\x83\x89\n"), [e(Some(1), "ol\u{e9}")]);
        // A dangling meta byte at the end is dropped.
        assert_eq!(entries(b": 1:0;ls\n\x83"), [e(Some(1), "ls")]);
    }

    #[test]
    fn skips_blank_records_and_keeps_an_incomplete_last_one() {
        assert_eq!(entries(b"\n\n: 1:0;ls\n\n"), [e(Some(1), "ls")]);
        assert_eq!(
            entries(b": 1:0;echo a \\\nb \\"),
            [e(Some(1), "echo a \nb ")]
        );
        assert!(entries(b"").is_empty());
    }

    #[test]
    fn replaces_invalid_utf8() {
        assert_eq!(entries(b": 1:0;x\xff\n"), [e(Some(1), "x\u{fffd}")]);
    }

    /// Has real zsh write `commands` with `fc -W` and returns the file.
    fn written_by_zsh(commands: &[&str], extended: bool) -> Vec<u8> {
        let dir = tempfile::tempdir().unwrap();
        let file = dir.path().join("history");
        let script = format!(
            "{} HISTFILE={} HISTSIZE=1000 SAVEHIST=1000; \
             for c in \"$@\"; do print -rs -- \"$c\"; done; fc -W",
            if extended {
                "setopt EXTENDED_HISTORY;"
            } else {
                "unsetopt EXTENDED_HISTORY;"
            },
            file.display()
        );
        // History is only kept in interactive shells; -f skips every rc file.
        let status = std::process::Command::new("zsh")
            .args(["-f", "-i", "-c", &script, "zsh"])
            .stdin(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .args(commands)
            .env_clear()
            .env("PATH", std::env::var_os("PATH").unwrap_or_default())
            .env("HOME", dir.path())
            .env("LANG", "C.UTF-8")
            .status()
            .expect("zsh runs");
        assert!(status.success());
        std::fs::read(file).unwrap()
    }

    const TRICKY: &[&str] = &[
        "ls -la",
        "echo one\ntwo",
        "echo a\n: 123:0;not a header",
        "echo ends with backslash \\",
        "echo backslash then spaces \\  ",
        "printf '%s\\n' x",
        "echo double \\\\",
        "echo ol\u{e9} \u{192} \u{2211} \u{65e5}\u{672c}",
        "echo trailing spaces   ",
    ];

    #[test]
    fn reads_back_what_zsh_writes_with_extended_history() {
        let bytes = written_by_zsh(TRICKY, true);
        assert!(bytes.contains(&META), "the sample exercises metafication");
        let mut read = Vec::new();
        for_each_entry(&bytes, |e| {
            assert!(e.ts.is_some(), "{:?}", e.cmd);
            read.push(e.cmd);
        });
        assert_eq!(read, TRICKY);
    }

    #[test]
    fn reads_back_what_zsh_writes_without_extended_history() {
        let commands: Vec<&str> = TRICKY
            .iter()
            .copied()
            .chain([": leading colon", ":"])
            .collect();
        let bytes = written_by_zsh(&commands, false);
        let mut read = Vec::new();
        for_each_entry(&bytes, |e| {
            assert_eq!(e.ts, None, "{:?}", e.cmd);
            read.push(e.cmd);
        });
        assert_eq!(read, commands);
    }

    #[test]
    fn rejects_malformed_headers() {
        assert_eq!(entries(b": x:0;ls\n"), [e(None, ": x:0;ls")]);
        assert_eq!(entries(b": 1:;ls\n"), [e(None, ": 1:;ls")]);
    }
}
