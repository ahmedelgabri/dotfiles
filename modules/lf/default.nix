{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.lf;

in {
  options = with lib; {
    my.lf = {
      enable = mkEnableOption ''
        Whether to enable lf module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ lf chafa mpv fzf ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/lf/lfrc" = { source = ./lfrc; };
              ".config/lf/preview-nix.sh" = {
                executable = true;
                source = ./preview.sh;
              };
            };
          };
        };
      };
    };
}
