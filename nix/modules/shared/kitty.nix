{...}: {
  flake.sharedModules.kitty = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin isLinux;
  in
    with lib;
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
                source = ../../../config/kitty;
              };
            };
          };
        }
      ];
}
