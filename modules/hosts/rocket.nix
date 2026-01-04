# Rocket host (aarch64-darwin)
{inputs, ...}: {
  flake.modules.darwin.rocket = {config, pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      defaults
      git
    ];

    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    networking.hostName = "rocket";

    # Import existing host-specific config from nix/hosts/
    imports = [../nix/hosts/rocket.nix];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      git
    ];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "rocket";
}
