{...}: {
  flake.sharedModules.tmux = {
    pkgs,
    lib,
    config,
    ...
  }: {
    environment = {
      shellAliases = {
        # https://github.com/direnv/direnv/wiki/Tmux
        tmux = "direnv exec / tmux";
      };
    };

    my.user = {
      packages = with pkgs; [
        tmux
        next-prayer
      ];
    };

    my.hm.file = {
      ".config/tmux" = {
        recursive = true;
        source = ../../../config/tmux;
      };
    };
  };
}
