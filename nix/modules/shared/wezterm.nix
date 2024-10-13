{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.wezterm;
  inherit (pkgs.stdenv) isDarwin isLinux;

in
{
  options = with lib; {
    my.modules.wezterm = {
      enable = mkEnableOption ''
        Whether to enable wezterm module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        homebrew.casks = [ "wezterm" ];
      })
      (mkIf isLinux {
        my = {
          user = { packages = with pkgs; [ wezterm ]; };
          env = {
            TERMINFO_DIRS = [
              "${pkgs.wezterm.terminfo}/share/terminfo"
            ];
          };
        };
      })

      {
        my.hm.file = {
          ".config/wezterm" = {
            recursive = true;
            source = ../../../config/wezterm;
          };
        };
      }
    ]);

}
