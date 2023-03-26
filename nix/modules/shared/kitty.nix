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
        my.user = {
          packages = with pkgs; [
            imagemagick # w3m kitty image support depends on imagemagick
            termpdfpy # only works with kitty
          ];
        };
      } else {
        my.user = {
          packages = with pkgs; [
            kitty
            imagemagick # w3m kitty image support depends on imagemagick
            termpdfpy # only works with kitty
          ];
        };
      })

      {
        my.env = {
          TERMINFO_DIRS = "$KITTY_INSTALLATION_DIR/terminfo";
        };

        my.hm.file = {
          ".config/kitty" = {
            recursive = true;
            source = ../../../config/kitty;
          };
        };
      }
    ]);
}
