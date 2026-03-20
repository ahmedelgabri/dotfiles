{
  pkgs,
  lib,
  config,
  ...
}: {
  config = with lib; {
    environment = {
      shellAliases = {
        agenix = "agenix -i ~/.ssh/agenix";
      };
    };
  };
}
