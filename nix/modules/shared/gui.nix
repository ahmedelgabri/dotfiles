{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.gui;
  alfred = pkgs.callPackage ../../pkgs/alfred.nix { };
  appcleaner = pkgs.callPackage ../../pkgs/appcleaner.nix { };
  sharedApps = with pkgs; [
    # sqlitebrowser
    # virtualbox
    vscodium
    slack
  ];

in {
  options = with lib; {
    my.gui = {
      enable = mkEnableOption ''
        Whether to enable gui module
      '';
    };
  };

  config = with lib;
  # To understand why this dance check these, it's mainly because of Darwin
  # https://github.com/LnL7/nix-darwin/issues/276
  # https://github.com/nix-community/home-manager/issues/1341
    mkIf cfg.enable (mkMerge [
      (mkIf pkgs.stdenv.isDarwin {
        environment.systemPackages = with pkgs;
          [ alfred appcleaner nextdns ] ++ sharedApps;
      })
      (mkIf pkgs.stdenv.isLinux {
        users.users.${username} = {
          packages = with pkgs;
            [ brave firefox obsidian zoom-us signal-desktop ] ++ sharedApps;
        };
      })
    ]);
}
