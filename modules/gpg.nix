{ pkgs, config, ... }:

{
  home-manager = {
    users.${config.settings.username} = { pkgs, ... }: {
      home = {
        packages = with pkgs;
          [
            keybase
            # keybase-gui # ???
          ];
        file = {
          ".config/gnupg/gpg-agent.conf".text = ''
            # Connects gpg-agent to the OSX keychain via the brew-installed
            # pinentry program from GPGtools. This is the OSX 'magic sauce',
            # allowing the gpg key's passphrase to be stored in the login
            # keychain, enabling automatic key signing.
            pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
            default-cache-ttl 600
            max-cache-ttl 7200'';
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ pinentry_mac gnupg ];
}
