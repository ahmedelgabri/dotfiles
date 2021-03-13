{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.syncthing;
  homeDir = config.my.user.home;

in {
  options = with lib; {
    my.modules.syncthing = {
      enable = mkEnableOption ''
        Whether to enable syncthing module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "launchd" options) then {
        my.user = { packages = with pkgs; [ syncthing ]; };
        # https://github.com/Homebrew/homebrew-core/blob/a567617d9592796a0008f3532f38f94798624dd8/Formula/syncthing.rb#L35
        launchd.user.agents."syncthing" = {
          command = "${pkgs.syncthing}/bin/syncthing -no-browser -no-restart";
          serviceConfig = {
            ProcessType = "Background";
            RunAtLoad = true;
            KeepAlive = { SuccessfulExit = false; };
            StandardOutPath = "${homeDir}/Library/Logs/syncthing.log";
            StandardErrorPath = "${homeDir}/Library/Logs/syncthing-error.log";
          };
        };
      } else {
        services.syncthing = {
          enable = true;
          user = config.my.username;
          configDir = "${config.my.user.home}/.config/syncthing";
        };
      })
    ]);
}
