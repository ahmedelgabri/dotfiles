# Hosts configuration module
# Defines all Darwin and NixOS host configurations
{
  inputs,
  self,
  lib,
  config,
  ...
}: let
  darwinHosts = {
    "pandoras-box" = "x86_64-darwin";
    "alcantara" = "aarch64-darwin";
    "rocket" = "aarch64-darwin";
  };

  linuxHosts = {
    "nixos" = "x86_64-linux";
  };

  # Shared configuration module (migrated from sharedConfiguration function)
  sharedModule = config.flake.sharedModules.default;

  # Common modules for all Darwin hosts
  darwinModules = [
    sharedModule
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.agenix.darwinModules.default
    ../modules/shared
    ../modules/darwin
  ];

  # Common modules for all NixOS hosts
  nixosModules = [
    sharedModule
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ../modules/shared
  ];

  # Build a Darwin configuration for a host
  mkDarwinHost = host: system:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        darwinModules
        ++ [
          ../hosts/${host}
        ];
    };

  # Build a NixOS configuration for a host
  mkNixosHost = host: system:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        nixosModules
        ++ [
          ../hosts/${host}
        ];
    };
in {
  flake = {
    darwinConfigurations = lib.mapAttrs mkDarwinHost darwinHosts;
    nixosConfigurations = lib.mapAttrs mkNixosHost linuxHosts;
  }
  # Convenience aliases for building
  # nix build './#pandoras-box' instead of './#darwinConfigurations.pandoras-box.system'
  // lib.mapAttrs (host: _: self.darwinConfigurations.${host}.system) darwinHosts;
}
