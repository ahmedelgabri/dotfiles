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
        packages = with pkgs; [
          # sqlitebrowser
          # brave # Linux only
          # firefox # Linux only?
          # obsidian # Linux only
          # zoom-us # Linux only
          # virtualbox
          vscodium
          slack
        ];
      };
    };
}
