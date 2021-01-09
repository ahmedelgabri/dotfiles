{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.gui;

in {
  options = with lib; {
    my.gui = {
      enable = mkEnableOption ''
        Whether to enable gui module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = {
        packages = with pkgs;
          (if stdenv.isDarwin then
            [ ]
          else [
            brave
            firefox
            obsidian
            zoom-us
            signal-desktop
          ]) ++ [
            # sqlitebrowser
            # virtualbox
            vscodium
            slack
          ];
      };
    };
}
