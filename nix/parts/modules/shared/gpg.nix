let
  module = {
    generic =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        inherit (config.home-manager.users."${config.my.username}") xdg;
      in
      {
        config = with lib; {
          environment.systemPackages = with pkgs; [
            gnupg
            (pkgs.writeShellScriptBin "vcs-gpg" ''
              if [ -n "$GIT_COMMITTER_DATE" ]; then
                # git hands out committer dates as raw "@<epoch> <tz>",
                # RFC 2822, or extended ISO 8601 — none of which gpg's
                # --faked-system-time parses; it silently treats them as
                # 1970-01-01. Normalize to a bare epoch ("!" freezes the
                # clock) and fail loudly instead of signing with a bogus
                # timestamp.
                case "$GIT_COMMITTER_DATE" in
                  @*)
                    epoch="''${GIT_COMMITTER_DATE#@}"
                    epoch="''${epoch%% *}"
                    ;;
                  *)
                    if ! epoch="$(${pkgs.coreutils}/bin/date -d "$GIT_COMMITTER_DATE" +%s)"; then
                      echo "vcs-gpg: cannot parse GIT_COMMITTER_DATE: $GIT_COMMITTER_DATE" >&2
                      exit 2
                    fi
                    ;;
                esac
                ${lib.getExe pkgs.gnupg} --faked-system-time "$epoch!" "$@"
              else
                ${lib.getExe pkgs.gnupg} "$@"
              fi
            '')
          ];

          environment.variables.GNUPGHOME = "${xdg.configHome}/gnupg";

          programs.gnupg.agent = {
            enable = true;
            enableSSHSupport = true;
          };
        };
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile = {
          "gnupg/gpg-agent.conf".text = ''
            # ${myConfig.nix_managed}

            allow-preset-passphrase

            default-cache-ttl 86400
            max-cache-ttl 86400'';

          "gnupg/gpg.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${myConfig.dotfilesDir}/config/gnupg/gpg.conf";
        };
      };
  };
in
{
  flake = {
    modules = {
      generic.gpg = module.generic;
      homeManager.gpg = module.homeManager;
    };
  };
}
