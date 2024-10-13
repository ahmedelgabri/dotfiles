{ inputs, lib, config, ... }:

let

  cfg = config.my.modules.hammerspoon;

in
{
  options = with lib; {
    my.modules.hammerspoon = {
      enable = mkEnableOption ''
        Whether to enable hammerspoon module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      homebrew.casks = [
        "hammerspoon"
      ];

      my.hm.file = {
        ".hammerspoon" = {
          recursive = true;
          source = ../../../config/.hammerspoon;
        };

        ".hammerspoon/Spoons/EmmyLua.spoon" = {
          source = "${inputs.spoons}/Source/EmmyLua.spoon";
          recursive = true;
        };

        ".hammerspoon/Spoons/Caffeine.spoon" = {
          source = "${inputs.spoons}/Source/Caffeine.spoon";
          recursive = true;
        };

        ".hammerspoon/Spoons/URLDispatcher.spoon" = {
          source = "${inputs.spoons}/Source/URLDispatcher.spoon";
          recursive = true;
        };
      };
    };
}
