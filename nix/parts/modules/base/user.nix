{
  config,
  pkgs,
  lib,
  options,
  ...
}:
with lib; let
  home =
    if pkgs.stdenv.isDarwin
    then "/Users/${config.my.username}"
    else "/home/${config.my.username}";
in {
  options.my.user = mkOption {
    type = options.users.users.type.functor.payload.elemType;
  };

  config = {
    users.users."${config.my.username}" = mkAliasDefinitions options.my.user;

    my.user = {
      inherit home;
      description = "Primary user account";
    };
  };
}
