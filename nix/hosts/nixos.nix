# NixOS host (x86_64-linux)
{inputs, ...}: {
  flake.modules.nixos.nixos = {config, pkgs, ...}: {
    imports = with inputs.self.modules.nixos; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      feature-defaults
    ];

    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default
      ./nixos # Host-specific NixOS configuration
    ];

    networking.hostName = "nixos";

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      # Add home-manager-specific modules here if needed
    ];
  };

  flake.nixosConfigurations =
    inputs.self.lib.mkNixos "x86_64-linux" "nixos";
}
