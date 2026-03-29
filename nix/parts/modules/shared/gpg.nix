let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
    in {
      config = with lib; {
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

        environment.variables.GNUPGHOME = "${xdg.configHome}/gnupg";

        programs.gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };
      };
    };

    homeManager = {myConfig, ...}: {
      xdg.configFile = {
        "gnupg/gpg-agent.conf".text = ''
          # ${myConfig.nix_managed}

          allow-preset-passphrase

          default-cache-ttl 86400
          max-cache-ttl 86400'';

        "gnupg/gpg.conf".text = ''
          # ${myConfig.nix_managed}
          ${builtins.readFile ../../../../config/gnupg/gpg.conf}'';
      };
    };
  };
in {
  flake = {
    modules = {
      generic.gpg = module.generic;
      homeManager.gpg = module.homeManager;
    };
  };
}
