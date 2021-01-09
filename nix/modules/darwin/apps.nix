{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.apps;
  alfred = pkgs.callPackage ../../pkgs/alfred.nix { };
  appcleaner = pkgs.callPackage ../../pkgs/appcleaner.nix { };
  obsidian = pkgs.callPackage ../../pkgs/obsidian.nix { };

in {
  options = with lib; {
    my.apps = {
      enable = mkEnableOption ''
        Whether to enable apps module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ alfred appcleaner obsidian ];
    };
}
