{ config, pkgs, ... }:

{
  nix.configureBuildUsers = true;

  homebrew.enable = true;
  homebrew.autoUpdate = true;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;

  imports = [ ./macos.nix ];
}
