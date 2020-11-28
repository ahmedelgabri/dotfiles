{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.kitty;

in {
  options = with lib; {
    my.kitty = {
      enable = mkEnableOption ''
        Whether to enable kitty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ kitty ];

      home-manager = {
        users.${username} = {
          home = {

            sessionVariables = {
              TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
            };

            file = {
              ".config/kitty" = {
                recursive = true;
                source = ./kitty;
              };
            };
          };
        };
      };
    };
}
