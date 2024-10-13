{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.kitty;
  inherit (pkgs.stdenv) isDarwin isLinux;

in
{
  options = with lib; {
    my.modules.kitty = {
      enable = mkEnableOption ''
        Whether to enable kitty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        homebrew.casks = [ "kitty" ];
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
    ]);
}
