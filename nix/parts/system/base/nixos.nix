let
  module = {inputs, ...}: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default
    ];
  };
in {
  flake.modules.nixos.system-base = module;
}
