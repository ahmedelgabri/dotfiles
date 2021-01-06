{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.apps;
  alfred = pkgs.callPackage ../../pkgs/alfred.nix { };
  appcleaner = pkgs.callPackage ../../pkgs/appcleaner.nix { };
  arq = pkgs.callPackage ../../pkgs/arq.nix { };
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
      environment.systemPackages = with pkgs; [
        arq
        alfred
        appcleaner
        obsidian
      ];
    };
}
