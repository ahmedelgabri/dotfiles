{
  config,
  lib,
  ...
}:
with lib; {
  options.my.env = mkOption {
    type = types.attrsOf (types.oneOf [types.str types.path (types.listOf (types.either types.str types.path))]);
    apply = mapAttrs (name: value:
      if isList value
      then
        if name == "TERMINFO_DIRS"
        then "$TERMINFO_DIRS:" + concatMapStringsSep ":" toString value
        else concatMapStringsSep ":" toString value
      else toString value);
    default = {};
    description = "Set environment variables";
  };

  config.environment.extraInit =
    concatStringsSep "\n"
    (mapAttrsToList (name: value: ''export ${name}="${value}"'') config.my.env);
}
