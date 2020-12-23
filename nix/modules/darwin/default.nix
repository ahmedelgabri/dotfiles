{ config, pkgs, ... }:

{
  imports = [ ./macos.nix ./hammerspoon.nix ./apps.nix ];
}
