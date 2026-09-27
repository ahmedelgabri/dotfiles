//! Shell commands run by coding agents (Claude Code, Codex, pi) are kept in
//! their own history next to .zsh_history instead of inside it, so they never
//! surface in up-arrow, substring search, or inline suggestions while staying
//! searchable from the Ctrl-R widget in config/zsh.d/zsh/config/extras.zsh.
//!
//! Storage is SQLite: concurrent agents get atomic writes and a busy timeout
//! from the engine, and `list` is a query rather than a scan of a growing
//! file. The widget uses the same four columns for shell history, where id is
//! the history number.

mod db;
mod query;
mod record;
mod repo;

use std::ffi::OsString;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::ExitCode;

use clap::error::{ContextKind, ContextValue, ErrorKind};
use clap::{Args, Parser, Subcommand};

/// An error that ends the program: `code` 1 for failures and argument errors
/// inside a subcommand, 64 for usage errors, as the Bash implementation did.
#[derive(Debug)]
pub struct Fail {
    pub code: u8,
    pub message: String,
}

impl Fail {
    pub fn new(message: impl Into<String>) -> Self {
        Fail {
            code: 1,
            message: message.into(),
        }
    }
}

#[derive(Parser)]
#[command(name = "zh", about = "Agent command history")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Record a Claude-Code-style hook payload read from stdin
    Record { agent: String },
    /// Print NUL-separated "id\ttime\tdir\tcmd" records, newest first, one
    /// row per command; id is always empty
    List {
        #[command(flatten)]
        filters: FilterArgs,
    },
    /// Print the newest record of CMD within the filters
    Show {
        #[command(flatten)]
        filters: FilterArgs,
        #[arg(last = true, required = true, value_name = "CMD")]
        cmd: String,
    },
    /// Delete every record of CMD; use `forget -- CMD` when CMD starts with `-`
    Forget {
        #[arg(value_name = "CMD")]
        cmd: String,
    },
    /// Print "count\tfailed\tprefix" per command prefix, most used first
    Stats {
        /// Words per prefix
        #[arg(
            long,
            value_name = "N",
            allow_hyphen_values = true,
            overrides_with = "words"
        )]
        words: Option<String>,
        /// Number of prefixes
        #[arg(
            long,
            value_name = "N",
            allow_hyphen_values = true,
            overrides_with = "limit"
        )]
        limit: Option<String>,
        #[command(flatten)]
        filters: FilterArgs,
    },
    /// Copy agent-run rows out of an atuin database
    ImportAtuin { path: Option<PathBuf> },
}

#[derive(Args, Default)]
pub struct FilterArgs {
    /// Records from DIR and below
    #[arg(long, value_name = "DIR", allow_hyphen_values = true)]
    pub dir: Vec<String>,
    /// Records from the jj workspace or git worktree holding DIR
    #[arg(long, value_name = "DIR", allow_hyphen_values = true)]
    pub repo: Vec<String>,
    /// Records from one agent
    #[arg(long, value_name = "NAME", allow_hyphen_values = true)]
    pub agent: Vec<String>,
    /// Records from one agent session
    #[arg(long, value_name = "ID", allow_hyphen_values = true)]
    pub session: Vec<String>,
    /// Every record: no deduplication, failed calls included
    #[arg(long, overrides_with = "all")]
    pub all: bool,
}

const SUBCOMMANDS: [&str; 6] = ["record", "list", "show", "forget", "stats", "import-atuin"];

fn main() -> ExitCode {
    let args: Vec<OsString> = std::env::args_os().collect();
    let result = match Cli::try_parse_from(&args) {
        Ok(cli) => run(cli.command),
        Err(error) => {
            let code = parse_error_code(&args, &error);
            let _ = error.print();
            return ExitCode::from(code);
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(fail) => {
            eprintln!("zh: {}", fail.message);
            ExitCode::from(fail.code)
        }
    }
}

/// Exit codes follow the Bash implementation: no or unknown subcommand is a
/// usage error (64), and so is anything wrong with a `stats` count, while
/// other argument errors inside a subcommand fail with 1.
fn parse_error_code(args: &[OsString], error: &clap::Error) -> u8 {
    if matches!(
        error.kind(),
        ErrorKind::DisplayHelp | ErrorKind::DisplayVersion
    ) {
        return 0;
    }
    let subcommand = args.get(1).and_then(|a| a.to_str());
    match subcommand {
        Some(name) if SUBCOMMANDS.contains(&name) => {
            if name == "stats" && concerns_stats_count(error) {
                64
            } else {
                1
            }
        }
        _ => 64,
    }
}

fn concerns_stats_count(error: &clap::Error) -> bool {
    match error.get(ContextKind::InvalidArg) {
        Some(ContextValue::String(arg)) => arg.starts_with("--words") || arg.starts_with("--limit"),
        _ => false,
    }
}

fn run(command: Command) -> Result<(), Fail> {
    match command {
        Command::Record { agent } => {
            let mut input = String::new();
            io::stdin()
                .read_to_string(&mut input)
                .map_err(|_| Fail::new("could not parse hook payload"))?;
            record::record(&agent, &input)
        }
        Command::List { filters } => query::list(&filters),
        Command::Show { filters, cmd } => query::show(&filters, &cmd),
        Command::Forget { cmd } => query::forget(&cmd),
        Command::Stats {
            words,
            limit,
            filters,
        } => {
            let words = count(words.as_deref().unwrap_or("2"))?;
            let limit = count(limit.as_deref().unwrap_or("30"))?;
            query::stats(&filters, words, limit)
        }
        Command::ImportAtuin { path } => query::import_atuin(path),
    }
}

fn count(value: &str) -> Result<usize, Fail> {
    let valid =
        !value.is_empty() && !value.starts_with('0') && value.bytes().all(|b| b.is_ascii_digit());
    match value.parse() {
        Ok(n) if valid => Ok(n),
        _ => Err(Fail {
            code: 64,
            message: "--words and --limit take positive integers".into(),
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn code(args: &[&str]) -> u8 {
        let args: Vec<OsString> = args.iter().map(OsString::from).collect();
        match Cli::try_parse_from(&args) {
            Ok(_) => 255,
            Err(error) => parse_error_code(&args, &error),
        }
    }

    #[test]
    fn usage_errors_exit_64() {
        assert_eq!(code(&["zh"]), 64);
        assert_eq!(code(&["zh", "--bogus"]), 64);
        assert_eq!(code(&["zh", "bogus"]), 64);
    }

    #[test]
    fn help_exits_0_where_clap_sees_the_flag() {
        assert_eq!(code(&["zh", "--help"]), 0);
        assert_eq!(code(&["zh", "-h"]), 0);
        assert_eq!(code(&["zh", "list", "--help"]), 0);
        assert_eq!(code(&["zh", "stats", "-h"]), 0);
        // A command, not a flag.
        assert_eq!(code(&["zh", "show", "--", "--help"]), 255);
    }

    #[test]
    fn subcommand_argument_errors_exit_1() {
        assert_eq!(code(&["zh", "list", "--bad"]), 1);
        assert_eq!(code(&["zh", "list", "--dir"]), 1);
        assert_eq!(code(&["zh", "list", "--", "x"]), 1);
        assert_eq!(code(&["zh", "show", "x"]), 1);
        assert_eq!(code(&["zh", "show", "--dir", "/a"]), 1);
        assert_eq!(code(&["zh", "record"]), 1);
        assert_eq!(code(&["zh", "stats", "--bogus"]), 1);
    }

    #[test]
    fn stats_count_errors_exit_64() {
        assert_eq!(code(&["zh", "stats", "--words"]), 64);
        assert_eq!(code(&["zh", "stats", "--limit"]), 64);
        for bad in ["0", "-1", "x", "1.5", "--all", "--help", "01", ""] {
            assert_eq!(count(bad).unwrap_err().code, 64, "{bad}");
        }
        assert_eq!(count("12").unwrap(), 12);
    }

    #[test]
    fn filters_repeat_and_combine() {
        let cli = Cli::try_parse_from([
            "zh", "list", "--dir", "/a", "--repo", "/b", "--dir", "/c", "--agent", "pi", "--agent",
            "claude", "--all", "--all",
        ])
        .unwrap();
        let Command::List { filters } = cli.command else {
            panic!()
        };
        assert_eq!(filters.dir, ["/a", "/c"]);
        assert_eq!(filters.repo, ["/b"]);
        assert_eq!(filters.agent, ["pi", "claude"]);
        assert!(filters.all);
    }

    #[test]
    fn stats_counts_take_the_last_value() {
        let cli = Cli::try_parse_from([
            "zh", "stats", "--words", "1", "--agent", "pi", "--words", "3",
        ])
        .unwrap();
        let Command::Stats { words, filters, .. } = cli.command else {
            panic!()
        };
        assert_eq!(words.as_deref(), Some("3"));
        assert_eq!(filters.agent, ["pi"]);
    }

    fn forgotten(args: &[&str]) -> Result<String, u8> {
        let args: Vec<OsString> = args.iter().map(OsString::from).collect();
        match Cli::try_parse_from(&args) {
            Ok(Cli {
                command: Command::Forget { cmd },
            }) => Ok(cmd),
            Ok(_) => panic!("not forget"),
            Err(error) => Err(parse_error_code(&args, &error)),
        }
    }

    #[test]
    fn forget_parses_like_every_other_subcommand() {
        assert_eq!(
            forgotten(&["zh", "forget", "echo dup"]),
            Ok("echo dup".into())
        );
        assert_eq!(forgotten(&["zh", "forget", "--", "-x"]), Ok("-x".into()));
        assert_eq!(forgotten(&["zh", "forget", "--", "--"]), Ok("--".into()));
        assert_eq!(
            forgotten(&["zh", "forget", "--", "--help"]),
            Ok("--help".into())
        );
        assert_eq!(
            forgotten(&["zh", "forget", "--", "--weird cmd"]),
            Ok("--weird cmd".into())
        );
        assert_eq!(forgotten(&["zh", "forget", "--help"]), Err(0));
        assert_eq!(forgotten(&["zh", "forget", "-x"]), Err(1));
        assert_eq!(forgotten(&["zh", "forget", "--weird cmd"]), Err(1));
        assert_eq!(forgotten(&["zh", "forget", "--weird", "cmd"]), Err(1));
        assert_eq!(forgotten(&["zh", "forget", "--"]), Err(1));
        assert_eq!(forgotten(&["zh", "forget"]), Err(1));
        assert_eq!(forgotten(&["zh", "forget", "a", "b"]), Err(1));
    }

    #[test]
    fn show_takes_a_hyphenated_command_after_the_separator() {
        let cli = Cli::try_parse_from(["zh", "show", "--dir", "/a", "--", "--x y"]).unwrap();
        let Command::Show { cmd, .. } = cli.command else {
            panic!()
        };
        assert_eq!(cmd, "--x y");
    }
}
