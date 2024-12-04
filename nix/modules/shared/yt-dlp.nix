{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.yt-dlp;
in {
  options = with lib; {
    my.modules.yt-dlp = {
      enable = mkEnableOption ''
        Whether to enable yt-dlp module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = {
        packages = with pkgs; [
          (yt-dlp.override {withAlias = true;})
        ];
      };

      my.hm.file = {
        ".config/yt-dlp" = {
          recursive = true;
          source = ../../../config/yt-dlp;
        };
      };
    };
}
