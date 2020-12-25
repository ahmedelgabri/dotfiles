{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.python;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.python = {
      enable = mkEnableOption ''
        Whether to enable python module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        PYTHONSTARTUP = "${xdg.configHome}/python/config.py";
      };

      users.users.${username} = {
        packages = with pkgs;
          [
            (python3.withPackages (ps:
              with ps; [
                pip
                black
                setuptools
                pylint
                grip
                pynvim
                vobject # Mutt calendar script
                python-language-server
                websocket_client # Wee-slack
              ]))
            # nixos.python38Packages.httpx
          ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/python" = {
                recursive = true;
                source = ../../../config/python;
              };
              ".config/pip" = {
                recursive = true;
                source = ../../../config/pip;
              };
            };
          };
        };
      };
    };
}
