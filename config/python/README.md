# Python startup

The Python feature sets `PYTHONSTARTUP` to `.pythonrc.py`. It adds colored prompts for supported terminals, tab completion, pretty-printing, readline history at `$XDG_CACHE_HOME/.pyhistory`, and `\e` to edit the previous input. The history keeps up to 1,000 entries. `XDG_CACHE_HOME` must name an existing writable directory.

Pretty-printing stores the last non-`None` result in Python's `builtins` namespace so `_` also works when the startup code is executed with a dictionary namespace.

`EDITOR` defaults to `vi`. Its executable and quoted arguments are split with `shlex` and launched without a shell. Buffer paths containing spaces remain single arguments, editor failures are reported, and temporary buffers are cleaned up on success or failure. Shell pipelines and redirections in `EDITOR` are not interpreted; put those in an executable wrapper script instead.

The flake's Python 3.14 is the lint and type-checking target. Ruff and ty check this file alongside the tests. See [Python tooling and startup tests](../../tests/README.md#python-tooling) for commands.
