let
  # Single owner of the remote-control socket path: emitted as the
  # KITTY_LISTEN_ON env var (for kitten clients in shells), into the
  # macOS launch-services command line kitty starts with, and into the
  # nix.conf fragment kitty.conf includes for CLI/Linux launches.
  kittyListenSocket = "unix:/tmp/kitty";

  module = {
    darwin = _: {
      config = {
        homebrew.casks = [ "kitty" ];
        environment.variables.KITTY_LISTEN_ON = kittyListenSocket;
        # KITTY_INSTALLATION_DIR only exists inside kitty; unguarded, every
        # other shell got a bogus ":/terminfo" entry appended.
        environment.extraInit = ''
          if [ -n "$KITTY_INSTALLATION_DIR" ]; then
            export TERMINFO_DIRS="$TERMINFO_DIRS:$KITTY_INSTALLATION_DIR/terminfo"
          fi
        '';
      };
    };

    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          my.user.packages = with pkgs; [ kitty ];
          environment.variables.KITTY_LISTEN_ON = kittyListenSocket;
          environment.extraInit = ''
            export TERMINFO_DIRS="$TERMINFO_DIRS:${pkgs.kitty.terminfo}/share/terminfo"
          '';
        };
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/kitty;
            sourceRoot = "${myConfig.dotfilesDir}/config/kitty";
            targetRoot = "kitty";
          }
          // {
            "kitty/macos-launch-services-cmdline".text = ''
              -o allow_remote_control=socket-only --single-instance --listen-on ${kittyListenSocket}
            '';
            "kitty/nix.conf".text = ''
              listen_on ${kittyListenSocket}
            '';
          };
      };
  };
in
{
  flake = {
    modules = {
      darwin.kitty = module.darwin;
      nixos.kitty = module.nixos;
      homeManager.kitty = module.homeManager;
    };
  };
}
