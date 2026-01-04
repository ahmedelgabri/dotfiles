# Host configurations for both Darwin and NixOS systems
# This module defines all system configurations managed by this flake
{
  inputs,
  self,
  lib,
  ...
}: let
  # Host definitions
  darwinHosts = {
    "pandoras-box" = "x86_64-darwin";
    "alcantara" = "aarch64-darwin";
    "rocket" = "aarch64-darwin";
  };

  linuxHosts = {
    "nixos" = "x86_64-linux";
  };

  # Helper function to map over hosts
  mapHosts = f: hostsMap: builtins.mapAttrs f hostsMap;
in {
  flake =
    {
      # Darwin (macOS) configurations
      darwinConfigurations =
        mapHosts
        (host: system:
          inputs.darwin.lib.darwinSystem {
            # This gets passed to modules as an extra argument
            specialArgs = {inherit inputs self;};
            inherit system;
            modules = [
              ../nix/settings.nix
              ../nix/shared-configuration.nix
              ../nix/overlays.nix
              inputs.home-manager.darwinModules.home-manager
              inputs.nix-homebrew.darwinModules.nix-homebrew
              inputs.agenix.darwinModules.default
              ../nix/modules/shared
              ../nix/modules/darwin
              ../nix/hosts/${host}.nix
            ];
          })
        darwinHosts;

      # NixOS configurations
      nixosConfigurations =
        mapHosts
        (host: system:
          inputs.nixpkgs.lib.nixosSystem {
            # This gets passed to modules as an extra argument
            specialArgs = {inherit inputs self;};
            inherit system;
            modules = [
              ../nix/settings.nix
              ../nix/shared-configuration.nix
              ../nix/overlays.nix
              inputs.home-manager.nixosModules.home-manager
              inputs.agenix.darwinModules.default
              ../nix/modules/shared
              ../nix/hosts/${host}
            ];
          })
        linuxHosts;
    }
    # Convenience outputs for easier building
    # nix build './#pandoras-box' instead of './#darwinConfigurations.pandoras-box.system'
    // mapHosts
    (host: _: self.darwinConfigurations.${host}.system)
    darwinHosts;
}
