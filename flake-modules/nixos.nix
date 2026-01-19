{
  inputs,
  self,
  config,
  ...
}: {
  flake = let
    linuxHosts = {
      "nixos" = "x86_64-linux";
    };

    mapHosts = f: hostsMap: builtins.mapAttrs f hostsMap;
  in {
    nixosConfigurations =
      mapHosts
      (host: system: (
        inputs.nixpkgs.lib.nixosSystem {
          # This gets passed to modules as an extra argument
          specialArgs = {inherit inputs;};
          inherit system;
          modules = [
            inputs.self.modules.generic.user-options
            inputs.self.modules.generic.core
            inputs.self.modules.nixos.core
            inputs.home-manager.nixosModules.home-manager
            "${self}/nix/modules/shared"
            "${self}/nix/hosts/${host}"
          ];
        }
      ))
      linuxHosts;
  };
}
