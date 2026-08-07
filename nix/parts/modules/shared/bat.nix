let
  module = {
    generic =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        inherit (config.home-manager.users."${config.my.username}") xdg;
      in
      {
        config = with lib; {
          environment = {
            shellAliases.cat = "bat";
            variables.BAT_CONFIG_PATH = "${xdg.configHome}/bat/config";
          };

          my.user.packages = with pkgs; [ bat ];
        };
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        myConfig,
        ...
      }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/bat;
          sourceRoot = "${myConfig.dotfilesDir}/config/bat";
          targetRoot = "bat";
        };

        # The custom theme only exists in bat's binary cache after
        # `bat cache --build`; without it every invocation (bat is the
        # global `cat` alias) warns "Unknown theme" and falls back to the
        # default. Rebuilding is idempotent and cheap, so run it on every
        # activation instead of tracking theme-file changes.
        home.activation.batCacheBuild = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe pkgs.bat} cache --build > /dev/null
        '';
      };
  };
in
{
  flake = {
    modules = {
      generic.bat = module.generic;
      homeManager.bat = module.homeManager;
    };
  };
}
