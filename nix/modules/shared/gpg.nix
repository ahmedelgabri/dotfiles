{
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
      environment.systemPackages = with pkgs; [
        gnupg
        (pkgs.writeShellScriptBin "vcs-gpg" ''
          if [ -n "$GIT_COMMITTER_DATE" ]; then
            ${lib.getExe pkgs.gnupg} --faked-system-time "$GIT_COMMITTER_DATE" "$@"
          else
            ${lib.getExe pkgs.gnupg} "$@"
          fi
        '')
      ];
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
