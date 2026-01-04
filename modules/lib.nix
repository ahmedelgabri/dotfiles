# Helper functions for creating system configurations
# These are used by host flake-parts modules to create configurations
{
  inputs,
  lib,
  ...
}:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };

  config.flake.lib = {
    # Create a NixOS configuration
    # Usage: flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "hostname";
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    # Create a Darwin configuration
    # Usage: flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "hostname";
    mkDarwin = system: name: {
      ${name} = inputs.darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          {nixpkgs.hostPlatform = lib.mkDefault system;}
        ];
      };
    };

    # Create a standalone Home Manager configuration
    # Usage: flake.homeConfigurations = inputs.self.lib.mkHome "x86_64-linux" "username";
    mkHome = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        modules = [
          inputs.self.modules.homeManager.${name}
        ];
      };
    };
  };
}
