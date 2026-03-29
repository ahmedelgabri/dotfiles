{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.environment;

  globalAliasCommands =
    mapAttrsToList (n: v: "alias -g -- ${n}=${escapeShellArg v}")
    (filterAttrs (_: v: v != null) cfg.zshGlobalAliases);
in {
  options.environment.zshGlobalAliases = mkOption {
    type = types.attrsOf (types.nullOr types.str);
    default = {};
    example = {
      "-h" = "-h 2>&1 | bat --language=help --style=plain";
      "L" = "| less";
    };
    description = ''
      An attribute set that maps zsh global aliases to their expansions.
      Global aliases expand anywhere in the command line, not just at the
      beginning. Set a value to null to remove a previously defined alias.
    '';
  };

  # mkAfter: global aliases expand at parse time, so they must be defined after
  # all plugins and function definitions to avoid mangling their code.
  config = mkIf (globalAliasCommands != []) {
    programs.zsh.interactiveShellInit = mkAfter (concatStringsSep "\n" globalAliasCommands);
  };
}
