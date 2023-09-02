{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.wezterm;

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
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.taps = [
          "wez/wezterm"
        ];

        homebrew.casks = [
          "wez/wezterm/wezterm"
        ];
      } else {
        my.user = { packages = with pkgs; [ wezterm ]; };
      })


      {
        my.env = {
          TERMINFO_DIRS = [
            "${pkgs.wezterm.terminfo}/share/terminfo"
          ];
        };

        my.hm.file = {
          ".config/wezterm" = {
            recursive = true;
            source = ../../../config/wezterm;
          };

          ".config/wezterm/terminfo.lua" = {
            text = ''return "${"${pkgs.wezterm.terminfo}/share/terminfo"}"'';
          };
        };
      }
    ]);

}
