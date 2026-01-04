# Git configuration - example of a cross-platform feature module
# This demonstrates the Dendritic Pattern:
# - Defines flake.modules.{darwin,nixos,homeManager}.git
# - Each module is self-contained and reusable
# - No knowledge of specific hosts
{...}: let
  # Shared git configuration for system-level (darwin/nixos)
  systemGitModule = {pkgs, ...}: {
    # System packages for git
    environment.systemPackages = with pkgs; [git];
  };

  # Shared git configuration for home-manager
  homeGitModule = {config, lib, pkgs, ...}: {
    programs.git = {
      enable = lib.mkDefault true;
      userName = lib.mkDefault config.my.name;
      userEmail = lib.mkDefault config.my.email;

      extraConfig = {
        # Add git configuration here
        init.defaultBranch = "main";
        pull.rebase = true;
        # ... more git config
      };
    };
  };
in {
  # Define the module for darwin systems
  flake.modules.darwin.git = systemGitModule;

  # Define the module for nixos systems
  flake.modules.nixos.git = systemGitModule;

  # Define the module for home-manager (works on both darwin and nixos)
  flake.modules.homeManager.git = homeGitModule;
}
