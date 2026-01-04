# Alcantara host configuration (aarch64-darwin)
# Imports feature modules and sets host-specific configuration
{inputs, ...}: {
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    # Import system-level feature modules from inputs.self.modules.darwin
    imports = with inputs.self.modules.darwin; [
      settings      # Custom options (config.my.*)
      nix          # Nix daemon configuration
      fonts        # Font packages
      defaults     # macOS system defaults
      git          # Git (system-level)
      # TODO: Add more feature modules as needed
      # vim, tmux, etc.
    ];

    # Import home-manager as a darwin module
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
      git
      # TODO: Add more home-manager modules
      # vim, tmux, etc.
    ];
  };
}
