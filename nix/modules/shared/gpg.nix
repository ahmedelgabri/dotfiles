{...}: {
  flake.sharedModules.gpg = {
    pkgs,
    lib,
    config,
    ...
  }: {
    environment.systemPackages = with pkgs; [gnupg];
    my.env = {GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";};

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    my.hm.file = {
      ".config/gnupg/gpg-agent.conf".text = ''
        # ${config.my.nix_managed}

        allow-preset-passphrase

        # Default: 600 seconds
        default-cache-ttl 86400

        # Default: 7200 seconds
        max-cache-ttl 86400'';

      ".config/gnupg/gpg.conf" = {
        text = ''
          # ${config.my.nix_managed}
          ${builtins.readFile ../../../config/gnupg/gpg.conf}'';
      };
    };
  };
}
