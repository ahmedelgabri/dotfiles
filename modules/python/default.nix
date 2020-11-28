{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.python;

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
      users.users.${username} = {
        packages = with pkgs;
          [
            # (python3.withPackages (ps:
            #   with ps; [
            #     pip
            #     black
            #     setuptools
            #     pylint
            #     grip
            #     pynvim
            #     vobject # Mutt calendar script
            #     # python-language-server
            #     # websocket-client # Wee-slack
            #   ]))
            # nixos.python38Packages.httpx
          ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/python/config.py" = { source = ./config.py; };
              ".config/pip/pip.conf" = { source = ./pip.conf; };
            };
          };
        };
      };
    };
}
