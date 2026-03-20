{
  config,
  lib,
  options,
  ...
}:
with lib; {
  options.my.user = mkOption {
    type = options.users.users.type.functor.payload.elemType;
  };

  config = {
    users.users."${config.my.username}" = mkAliasDefinitions options.my.user;

    my.user.description = "Primary user account";
  };
}
