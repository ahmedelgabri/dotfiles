{
  generic = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = with lib; {
      my.user.packages = with pkgs; [
        (yt-dlp.override {withAlias = true;})
      ];
    };
  };

  homeManager = {
    lib,
    myConfig,
    ...
  }:
    with lib; {
      xdg.configFile."yt-dlp" = {
        recursive = true;
        source = ../../../../config/yt-dlp;
      };
    };
}
