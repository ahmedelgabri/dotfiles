{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.gpg;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.gpg = {
      enable = mkEnableOption ''
        Whether to enable gpg module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ pinentry_mac gnupg ];
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
                # Connects gpg-agent to the OSX keychain via the brew-installed
                # pinentry program from GPGtools. This is the OSX 'magic sauce',
                # allowing the gpg key's passphrase to be stored in the login
                # keychain, enabling automatic key signing.
                pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
                default-cache-ttl 600
                max-cache-ttl 7200'';

              ".config/gnupg/gpg.conf" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ../../config/gnupg/gpg.conf}'';
              };
            };
          };
        };
      };
    };
}
