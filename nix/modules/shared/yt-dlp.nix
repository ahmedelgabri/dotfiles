{...}: {
  flake.sharedModules.yt-dlp = {
    pkgs,
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
          source = ../../../config/yt-dlp;
        };
      };
    };
  };
}
