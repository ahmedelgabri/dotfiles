{
  inputs,
  self,
  ...
}: {
  flake = let
    darwinHosts = {
      "pandoras-box" = "x86_64-darwin";
      "alcantara" = "aarch64-darwin";
      "rocket" = "aarch64-darwin";
    };

    mapHosts = f: hostsMap: builtins.mapAttrs f hostsMap;
  in
    {
      darwinConfigurations =
        mapHosts
        (host: system: (inputs.darwin.lib.darwinSystem
          {
            # This gets passed to modules as an extra argument
            specialArgs = {inherit inputs;};
            inherit system;
            modules = [
              inputs.self.modules.generic.user-options
              inputs.self.modules.generic.core
              inputs.self.modules.darwin.core
              inputs.home-manager.darwinModules.home-manager
              inputs.nix-homebrew.darwinModules.nix-homebrew
              "${self}/nix/modules/darwin"
              "${self}/nix/modules/shared"
              "${self}/nix/hosts/${host}.nix"
            ];
          }))
        darwinHosts;
    }
    // mapHosts
    # for convenience
    # nix build './#darwinConfigurations.pandoras-box.system'
    # vs
    # nix build './#pandoras-box'
    # Move them to `outputs.packages.<system>.name`
    (host: _: self.darwinConfigurations.${host}.system)
    darwinHosts;
}
