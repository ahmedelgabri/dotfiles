{inputs, ...}: let
  kittyModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin isLinux;
  in {
    config = with lib;
      mkMerge [
        (mkIf isDarwin {
          homebrew.casks = ["kitty"];
          my = {
            env = {
              TERMINFO_DIRS = [
                "$KITTY_INSTALLATION_DIR/terminfo"
              ];
            };
          };
        })
        (mkIf isLinux {
          my = {
            user = {
              packages = with pkgs; [
                kitty
              ];
            };

            env = {
              TERMINFO_DIRS = [
                "${pkgs.kitty.terminfo}/share/terminfo"
              ];
            };
          };
        })

        {
          my = {
            hm.file = {
              ".config/kitty" = {
                recursive = true;
                source = ../../config/kitty;
              };
            };
          };
        }
      ];
  };
in {
  flake.modules.darwin.kitty = kittyModule;
  flake.modules.nixos.kitty = kittyModule;
}
