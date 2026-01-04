# Alcantara host (aarch64-darwin)
{inputs, ...}: {
  # Define the host configuration module
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    # Import system modules
    imports = with inputs.self.modules.darwin; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      defaults
      feature-defaults
    ];

    # Import external modules
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    # Host-specific configuration
    networking.hostName = "alcantara";

    # Enable specific features for this host
    my.modules = {
      mail.enable = true;
      gpg.enable = true;
      discord.enable = true;
    };

    # Host-specific user packages
    my.user.packages = with pkgs; [
      amp-cli
      codex
      opencode
    ];

    # Host-specific homebrew casks
    homebrew.casks = [
      "jdownloader"
      "signal"
      "monodraw"
      "sony-ps-remote-play"
      "helium-browser"
    ];

    # Home-manager configuration for this host
    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      # Add home-manager-specific modules here if needed
    ];
  };

  # Create the actual darwinConfiguration
  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
}
