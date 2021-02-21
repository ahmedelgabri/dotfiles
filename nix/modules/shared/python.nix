{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.python;
  xdg = config.home-manager.users.${config.my.username}.xdg;

in {
  options = with lib; {
    my.modules.python = {
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

      my.user = {
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
        users.${config.my.username} = {
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
