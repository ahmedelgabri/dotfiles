{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.mpv;

in
{
  options = with lib; {
    my.modules.mpv = {
      enable = mkEnableOption ''
        Whether to enable mpv module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.casks = [ "mpv" "iina" ];
      } else {
        my.user = { packages = with pkgs; [ mpv ]; };
      })

      {
        my.hm.file = {
          ".config/mpv" = {
            recursive = true;
            source = ../../../config/mpv;
          };
        };
      }
    ]);
}
