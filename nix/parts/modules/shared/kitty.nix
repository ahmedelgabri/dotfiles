let
  # Single owner of the remote-control socket path: emitted both as the
  # KITTY_LISTEN_ON env var (for kitten clients in shells) and into the
  # macOS launch-services command line kitty starts with.
  kittyListenSocket = "unix:/tmp/kitty";

  module = {
    darwin = _: {
      config = {
        homebrew.casks = [ "kitty" ];
        environment.variables.KITTY_LISTEN_ON = kittyListenSocket;
        environment.extraInit = ''
          export TERMINFO_DIRS="$TERMINFO_DIRS:$KITTY_INSTALLATION_DIR/terminfo"
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
              -o allow_remote_control=yes --single-instance --listen-on ${kittyListenSocket}
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
