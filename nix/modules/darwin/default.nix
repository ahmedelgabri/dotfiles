{ config, pkgs, ... }:

{
  nix.configureBuildUsers = true;

  homebrew.enable = true;
  homebrew.global.brewfile = true;
  homebrew.onActivation.autoUpdate = true;
  homebrew.onActivation.upgrade = true;
  homebrew.onActivation.cleanup = "zap";

  imports = [ ./macos.nix ];
}
