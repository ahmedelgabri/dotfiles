let
  module = {
    generic =
      { pkgs, ... }:
      {
        my.user.packages = with pkgs; [ zk ];
      };

    darwin =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        homeDir = config.my.user.home;
        notesDir = "${homeDir}/Sync/notes";
      in
      {
        imports = [ module.generic ];

        config = {
          my.user.packages = with pkgs; [ watchexec ];

          launchd.user.agents."notes-index" = {
            serviceConfig = {
              ProgramArguments = [
                (lib.getExe pkgs.watchexec)
                "--shell=none"
                "--debounce"
                "10s"
                "--watch"
                notesDir
                "--exts"
                "md,markdown"
                "--ignore"
                "**/.obsidian/**"
                "--ignore"
                "**/.zk/**"
                "--"
                (lib.getExe pkgs.neovim-unwrapped)
                "--headless"
                "--clean"
                "-u"
                "NONE"
                "-l"
                "${homeDir}/.dotfiles/config/nvim/lua/_/notes/cli.lua"
                "--"
                "--quiet"
              ];
              RunAtLoad = true;
              KeepAlive = true;
              ProcessType = "Background";
              LowPriorityIO = true;
              StandardOutPath = "${homeDir}/Library/Logs/notes-index-output.log";
              StandardErrorPath = "${homeDir}/Library/Logs/notes-index-error.log";
              EnvironmentVariables = {
                NOTES_DIR = notesDir;
                ZK_NOTEBOOK_DIR = notesDir;
                XDG_CACHE_HOME = "${homeDir}/.cache";
              };
            };
          };
        };
      };

    homeManager = _: {
      xdg.configFile = {
        "zk/config.toml".source = ../../../../config/zk/config.toml;
        "zk/templates" = {
          recursive = true;
          source = ../../../../config/zk/templates;
        };
      };
    };
  };
in
{
  flake = {
    modules = {
      generic.zk = module.generic;
      darwin.zk = module.darwin;
      homeManager.zk = module.homeManager;
    };
  };
}
