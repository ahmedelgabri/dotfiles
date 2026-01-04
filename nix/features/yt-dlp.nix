{inputs, ...}: let
  # The actual NixOS module for yt-dlp configuration
  yt-dlpModule = {
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
            source = ../../config/yt-dlp;
          };
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.yt-dlp = yt-dlpModule;
  flake.modules.nixos.yt-dlp = yt-dlpModule;
}
