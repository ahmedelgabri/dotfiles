# Pandoras-box host (x86_64-darwin)
{inputs, ...}: {
  flake.modules.darwin.pandoras-box = {config, pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      defaults
    ];

    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    # Host-specific configuration
    networking.hostName = "pandoras-box";

    my.modules = {
      mail.enable = true;
      gpg.enable = true;
      discord.enable = true;
    };

    homebrew.casks = [
      # "arq" # I need a specific version so I will handle it myself.
      "transmit"
      "jdownloader"
      "brave-browser"
      "signal"
    ];

    # Home-manager configuration for this host
    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      # Add home-manager modules here
    ];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "x86_64-darwin" "pandoras-box";
}
