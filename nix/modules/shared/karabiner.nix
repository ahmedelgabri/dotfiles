{
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.karabiner;
in {
  options = with lib; {
    my.modules.karabiner = {
      enable = mkEnableOption ''
        Whether to enable karabiner module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      homebrew.casks = [
        "karabiner-elements"
      ];

      my.hm.file = {
        ".config/karabiner/karabiner.json" = {
          source = ../../../config/karabiner/karabiner.json;
        };
      };
    };
}
