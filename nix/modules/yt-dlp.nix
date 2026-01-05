{inputs, ...}: let
  yt-dlpModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
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
  flake.modules.darwin.yt-dlp = yt-dlpModule;
  flake.modules.nixos.yt-dlp = yt-dlpModule;
}
