use std::sync::LazyLock;
use std::time::{SystemTime, UNIX_EPOCH};

use regex::{Regex, RegexBuilder};
use serde_json::{Deserializer, Value};

use crate::{Fail, db};

// Generic credential shapes plus provider token shapes (AWS, GitHub, Slack,
// Stripe, Anthropic, OpenAI, GitLab, npm, Google) and PEM private keys.
// Agents paste tokens into commands more readily than a human typing at a
// prompt does. The sk- shapes keep a leading \b so names like "task-..." pass,
// and the legacy OpenAI shape allows no dashes so kebab-case names do too.
//
// Matching is case-insensitive with simple case folding and Unicode word
// boundaries, so a few shapes jq's Oniguruma caught, such as "PAßWORD=" (full
// folding) or a zero-width joiner before "TOKEN=", are recorded.
const SECRET_PATTERN: &str = concat!(
    r"\b[A-Z_]*(TOKEN|SECRET|PASSWORD|API_?KEY)[A-Z_]*=",
    r"|--(password|token|secret|api-key)[= ]",
    r"|authorization: ?(bearer|basic) ",
    r"|^sshpass ",
    r"|gh auth login --with-token",
    r"|AKIA[0-9A-Z]{16}",
    r"|gh[pousr]_[A-Za-z0-9]{36,}",
    r"|github_pat_[A-Za-z0-9_]{22,}",
    r"|xox[baprs]-[0-9A-Za-z-]{10,}",
    r"|hooks\.slack\.com/services/",
    r"|[sr]k_(live|test)_[0-9A-Za-z]{24,}",
    r"|\bsk-ant-(api|admin|oat)[0-9]{2}-[A-Za-z0-9_-]{20,}",
    r"|\bsk-(proj|svcacct|admin)-[A-Za-z0-9_-]{40,}",
    r"|\bsk-[A-Za-z0-9]{48}\b",
    r"|glpat-[A-Za-z0-9_-]{20,}",
    r"|\bnpm_[A-Za-z0-9]{36}\b",
    r"|AIza[0-9A-Za-z_-]{35}",
    r"|-----BEGIN [A-Z ]*PRIVATE KEY",
);

static SECRET: LazyLock<Regex> = LazyLock::new(|| {
    RegexBuilder::new(SECRET_PATTERN)
        .case_insensitive(true)
        .build()
        .expect("secret pattern compiles")
});

#[derive(Debug, PartialEq)]
pub struct Pending {
    pub cmd: String,
    pub cwd: String,
    pub session: String,
    pub status: &'static str,
    pub description: String,
}

pub fn is_secret(text: &str) -> bool {
    SECRET.is_match(text)
}

/// A string field, or "" for anything else. NULs are dropped because the
/// picker frames rows with them.
fn text(value: Option<&Value>) -> String {
    value
        .and_then(Value::as_str)
        .unwrap_or("")
        .replace('\0', "")
}

/// Every JSON document in the payload, parsed before anything is written so
/// a malformed one records nothing. A document without a string Bash
/// command (other tools, odd shapes) or with a credential is skipped.
pub fn parse(input: &str) -> Result<Vec<Pending>, serde_json::Error> {
    let mut pending = Vec::new();
    for document in Deserializer::from_str(input).into_iter::<Value>() {
        let document = document?;
        let Some(cmd) = document
            .pointer("/tool_input/command")
            .and_then(Value::as_str)
        else {
            continue;
        };
        let cmd = cmd.replace('\0', "");
        let description = text(document.pointer("/tool_input/description"));
        if is_secret(&cmd) || is_secret(&description) {
            continue;
        }
        // PostToolUseFailure is Claude's report of any failed call (denied,
        // interrupted, tool error); Codex and pi never send it, so "failed"
        // is the hook's classification, not an exit status.
        let failed =
            document.get("hook_event_name").and_then(Value::as_str) == Some("PostToolUseFailure");
        pending.push(Pending {
            cmd,
            cwd: text(document.get("cwd")),
            session: text(document.get("session_id")),
            status: if failed { "failed" } else { "ran" },
            description,
        });
    }
    Ok(pending)
}

pub fn record(agent: &str, input: &str) -> Result<(), Fail> {
    let pending = parse(input).map_err(|_| Fail::new("could not parse hook payload"))?;
    if pending.is_empty() {
        return Ok(());
    }
    let (mut conn, path) = db::open_or_create()?;
    let fail =
        |error: rusqlite::Error| Fail::new(format!("could not write {}: {error}", path.display()));
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    let tx = conn.transaction().map_err(fail)?;
    for p in &pending {
        tx.execute(
            "INSERT INTO commands (ts, agent, cwd, cmd, session, status, description)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            (
                ts,
                agent,
                &p.cwd,
                &p.cmd,
                &p.session,
                p.status,
                &p.description,
            ),
        )
        .map_err(fail)?;
    }
    tx.commit().map_err(fail)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn random(chars: &str, n: usize) -> String {
        chars.chars().cycle().skip(7).step_by(3).take(n).collect()
    }

    const ALNUM: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const ALNUM_DASH: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-";

    #[test]
    fn drops_credential_shapes() {
        let secrets = [
            "GITHUB_TOKEN=abc gh pr list".to_string(),
            "export aws_secret_access_key=x".to_string(),
            "mysql --password=hunter2".to_string(),
            "curl --token abc".to_string(),
            "curl -H 'Authorization: Bearer abc'".to_string(),
            "sshpass -p x ssh host".to_string(),
            "echo x | gh auth login --with-token".to_string(),
            format!(
                "aws s3 ls AKIA{}",
                random("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", 16)
            ),
            format!("echo ghp_{}", random(ALNUM, 36)),
            format!("echo github_pat_{}", random(ALNUM, 22)),
            format!("curl -d token=xoxb-{}", random(ALNUM, 12)),
            "curl https://hooks.slack.com/services/T0/B0/x".to_string(),
            format!("stripe sk_live_{}", random(ALNUM, 24)),
            format!(
                "curl -H 'x-api-key: sk-ant-api03-{}AA'",
                random(ALNUM_DASH, 95)
            ),
            format!("export K=sk-ant-admin01-{}", random(ALNUM_DASH, 80)),
            format!("claude setup-token sk-ant-oat01-{}", random(ALNUM_DASH, 80)),
            format!("OPENAI=sk-proj-{} python x.py", random(ALNUM_DASH, 150)),
            format!("echo sk-svcacct-{}", random(ALNUM_DASH, 120)),
            format!("echo sk-admin-{}", random(ALNUM_DASH, 60)),
            format!("curl -u sk-{} api", random(ALNUM, 48)),
            format!(
                "git clone https://oauth2:glpat-{}@gitlab.com/x.git",
                random(ALNUM_DASH, 20)
            ),
            format!(
                "npm config set //registry.npmjs.org/:_authToken npm_{}",
                random(ALNUM, 36)
            ),
            format!(
                "curl 'https://maps.googleapis.com/?key=AIza{}'",
                random(ALNUM_DASH, 35)
            ),
            "cat > k <<EOF\n-----BEGIN RSA PRIVATE KEY-----\nMIIE\nEOF".to_string(),
            "printf '%s' '-----BEGIN EC PRIVATE KEY-----' > k".to_string(),
            "echo '-----BEGIN OPENSSH PRIVATE KEY-----'".to_string(),
            "echo '-----BEGIN PRIVATE KEY-----'".to_string(),
        ];
        for secret in &secrets {
            assert!(is_secret(secret), "{secret}");
        }
    }

    #[test]
    fn keeps_near_misses() {
        let commands = [
            "ls sk-test-fixture-command-output.json",
            "echo sk-proj-placeholder-not-real",
            "task-list --all",
            "ask-for-help",
            "npm_config_cache=/tmp/x npm ci",
            "ls task-proj-this-is-a-long-fixture-name-not-a-real-api-key",
            "ls task-ant-api03-this-is-an-ordinary-file",
            "echo '-----BEGIN PUBLIC KEY-----'",
            "rg AIza src/",
            "ssh-keygen -t ed25519 -f ~/.ssh/id",
            "echo $TOKEN",
            "rg -n password src/",
        ];
        for command in commands {
            assert!(!is_secret(command), "{command}");
        }
    }

    // Approved differences from jq's Oniguruma: these used to be dropped.
    #[test]
    fn records_unicode_shapes_rust_regex_does_not_fold() {
        assert!(!is_secret("PAßWORD=x"));
        assert!(!is_secret("x\u{200d}TOKEN=x"));
        // Plain case-insensitive matches still work.
        assert!(is_secret("password=x"));
        assert!(is_secret("x TOKEN=x"));
    }

    fn one(json: &str) -> Pending {
        let mut all = parse(json).unwrap();
        assert_eq!(all.len(), 1, "{json}");
        all.remove(0)
    }

    #[test]
    fn parses_claude_payloads() {
        let p = one(
            r#"{"hook_event_name":"PostToolUse","session_id":"s1","cwd":"/r",
                "tool_input":{"command":"ls -la","description":"List files"}}"#,
        );
        assert_eq!(
            p,
            Pending {
                cmd: "ls -la".into(),
                cwd: "/r".into(),
                session: "s1".into(),
                status: "ran",
                description: "List files".into()
            }
        );
        let p = one(r#"{"hook_event_name":"PostToolUseFailure","tool_input":{"command":"rm x"}}"#);
        assert_eq!(p.status, "failed");
    }

    #[test]
    fn odd_fields_become_empty() {
        let p = one(r#"{"cwd":5,"session_id":{},"tool_input":{"command":"c","description":[1]}}"#);
        assert_eq!(
            (p.cwd, p.session, p.description),
            ("".into(), "".into(), "".into())
        );
    }

    #[test]
    fn documents_without_a_string_command_are_skipped() {
        for json in [
            r#"{"tool_input":{"command":5}}"#,
            r#"{"tool_input":"ls"}"#,
            r#"{"tool_name":"Read"}"#,
            r#"5"#,
            r#"[]"#,
        ] {
            assert!(parse(json).unwrap().is_empty(), "{json}");
        }
    }

    #[test]
    fn empty_input_is_nothing() {
        assert!(parse("").unwrap().is_empty());
        assert!(parse(" \n\t").unwrap().is_empty());
    }

    #[test]
    fn every_document_counts_and_any_bad_one_fails_all() {
        let two = r#"{"tool_input":{"command":"a"}} {"tool_input":{"command":"b"}}"#;
        let cmds: Vec<_> = parse(two).unwrap().into_iter().map(|p| p.cmd).collect();
        assert_eq!(cmds, ["a", "b"]);
        assert!(parse(r#"{"tool_input":{"command":"a"}} {"#).is_err());
        assert!(parse("nope").is_err());
    }

    #[test]
    fn nuls_are_stripped() {
        let p = one(
            r#"{"cwd":"/a\u0000b","tool_input":{"command":"x\u0000y","description":"d\u0000"}}"#,
        );
        assert_eq!(
            (p.cmd.as_str(), p.cwd.as_str(), p.description.as_str()),
            ("xy", "/ab", "d")
        );
    }

    #[test]
    fn secrets_in_descriptions_drop_the_record() {
        let json = format!(
            r#"{{"tool_input":{{"command":"curl example.com","description":"use ghp_{}"}}}}"#,
            random(ALNUM, 36)
        );
        assert!(parse(&json).unwrap().is_empty());
    }
}
