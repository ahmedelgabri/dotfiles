# Default feature module enables
# This module sets sensible defaults for which features should be enabled
# Hosts can override these by setting my.modules.<feature>.enable explicitly
{lib, ...}: let
  # Shared module that works on both darwin and nixos
  featureDefaultsModule = {
    config,
    lib,
    ...
  }: {
    # Set default enables for commonly used features
    my.modules = {
      # Core shell and development tools
      shell.enable = lib.mkDefault true;
      git.enable = lib.mkDefault true;
      ssh.enable = lib.mkDefault true;
      vim.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;

      # Terminal and file management
      kitty.enable = lib.mkDefault true;
      bat.enable = lib.mkDefault true;
      yazi.enable = lib.mkDefault true;
      ripgrep.enable = lib.mkDefault true;

      # Media and utilities
      mpv.enable = lib.mkDefault true;
      misc.enable = lib.mkDefault true;
      yt-dlp.enable = lib.mkDefault true;

      # Development environments
      python.enable = lib.mkDefault true;
      node.enable = lib.mkDefault true;
      go.enable = lib.mkDefault true;
      rust.enable = lib.mkDefault true;

      # Applications
      gui.enable = lib.mkDefault true;
      zk.enable = lib.mkDefault true;
      ghostty.enable = lib.mkDefault true;
      ai.enable = lib.mkDefault true;
      agenix.enable = lib.mkDefault true;

      # Discord is not enabled by default (opt-in)
      discord.enable = lib.mkDefault false;

      # Mail and GPG are not enabled by default (opt-in)
      mail.enable = lib.mkDefault false;
      gpg.enable = lib.mkDefault false;
    };
  };
in {
  # Make this module available for both darwin and nixos
  flake.modules.darwin.feature-defaults = featureDefaultsModule;
  flake.modules.nixos.feature-defaults = featureDefaultsModule;
}
