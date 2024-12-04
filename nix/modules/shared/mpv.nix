{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.mpv;
  inherit (pkgs.stdenv) isDarwin;
in {
  options = with lib; {
    my.modules.mpv = {
      enable = mkEnableOption ''
        Whether to enable mpv module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf isDarwin {
        homebrew.casks = ["iina"];
      })

      {
        my.user = {packages = with pkgs; [mpv];};
        my.hm.file = {
          ".config/mpv" = {
            recursive = true;
            source = ../../../config/mpv;
          };
        };
      }
    ]);
}
