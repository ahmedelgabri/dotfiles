{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.agenix;
in {
  options = with lib; {
    my.modules.agenix = {
      enable = mkEnableOption ''
        Whether to enable agenix module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment = {
        shellAliases = {
          agenix = "agenix -i ~/.ssh/agenix";
        };
      };
    };
}
