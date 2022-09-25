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
    ]);
}
