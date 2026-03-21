let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [
          (yt-dlp.override {withAlias = true;})
        ];
      };
    };

    homeManager = _: {
      xdg.configFile."yt-dlp" = {
        recursive = true;
        source = ../../../../config/yt-dlp;
      };
    };
  };
in {
  flake = {
    modules = {
      generic."yt-dlp" = module.generic;
      homeManager."yt-dlp" = module.homeManager;
    };
  };
}
