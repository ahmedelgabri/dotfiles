{inputs, ...}: let
  # The actual NixOS module for gpg configuration
  gpgModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.gpg;
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
              ${builtins.readFile ../../config/gnupg/gpg.conf}'';
          };
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.gpg = gpgModule;
  flake.modules.nixos.gpg = gpgModule;
}
