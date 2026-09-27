use std::process::{Command, Stdio};

/// The jj workspace or git worktree holding `dir`, else `dir` itself, so
/// "agents here" covers the whole checkout from any subdirectory. jj and git
/// resolve symlinks, so records whose cwd went through one do not match.
pub fn root(dir: &str) -> String {
    let mut jj = Command::new("jj");
    jj.args(["--ignore-working-copy", "root"]).current_dir(dir);
    let mut git = Command::new("git");
    git.args(["-C", dir, "rev-parse", "--show-toplevel"]);
    output(jj)
        .or_else(|| output(git))
        .unwrap_or_else(|| dir.to_owned())
}

fn output(mut command: Command) -> Option<String> {
    let out = command
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    String::from_utf8(out.stdout)
        .ok()
        .map(strip_trailing_newlines)
}

/// What shell command substitution strips: every trailing LF, nothing else,
/// so a directory name ending in spaces keeps them.
fn strip_trailing_newlines(mut s: String) -> String {
    while s.ends_with('\n') {
        s.pop();
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_only_trailing_newlines() {
        assert_eq!(strip_trailing_newlines("/a b  \n\n\n".into()), "/a b  ");
        assert_eq!(strip_trailing_newlines("/a\nb\n".into()), "/a\nb");
        assert_eq!(strip_trailing_newlines(" \t".into()), " \t");
    }

    #[test]
    fn falls_back_to_the_directory() {
        assert_eq!(root("/definitely/not/here"), "/definitely/not/here");
    }
}
