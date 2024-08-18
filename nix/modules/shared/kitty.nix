{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.kitty;

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
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.casks = [ "kitty" ];
      } else {
        my.user = {
          packages = with pkgs; [
            kitty
          ];
        };
      })

      {
        my = {
          user = {
            packages = with pkgs; [
              imagemagick # w3m kitty image support depends on imagemagick
              termpdfpy # only works with kitty
            ];
          };

          env = {
            TERMINFO_DIRS = [
              # "${pkgs.kitty.terminfo}/share/terminfo"
              "$KITTY_INSTALLATION_DIR/terminfo"
            ];
          };

          hm.file = {
            ".config/kitty" = {
              recursive = true;
              source = ../../../config/kitty;
            };


            ".config/kitty/kitty-nix.conf" = with config.my; {
              text = ''
                # ${nix_managed}
                # vim: ft=gitconfig

                shell ${pkgs.zsh}/bin/zsh
              '';
            };
          };

        };
      }
    ]);
}
