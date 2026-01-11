{...}: {
  flake.sharedModules.ripgrep = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
      my.env = {RIPGREP_CONFIG_PATH = "$XDG_CONFIG_HOME/ripgrep/config";};

      my.user = {packages = with pkgs; [ripgrep];};

      my.hm.file = {
        ".config/ripgrep" = {
          recursive = true;
          source = ../../../config/ripgrep;
        };
      };
    };
  };
}
