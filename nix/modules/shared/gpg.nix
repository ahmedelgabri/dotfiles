{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.modules.gpg;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.modules.gpg = {
      enable = mkEnableOption ''
        Whether to enable gpg module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ gnupg ];
      environment.variables = { GNUPGHOME = "${xdg.configHome}/gnupg"; };

      users.users.${config.settings.username} = {
        packages = with pkgs;
          [
            keybase
            # keybase-gui # ???
          ];
      };

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      home-manager = {
        users.${config.settings.username} = { pkgs, ... }: {
          home = {
            file = {
              ".config/gnupg/gpg-agent.conf".text = ''
                default-cache-ttl 600
                max-cache-ttl 7200'';

              ".config/gnupg/gpg.conf" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ../../../config/gnupg/gpg.conf}'';
              };
            };
          };
        };
      };
    };
}
