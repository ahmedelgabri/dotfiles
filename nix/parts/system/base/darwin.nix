let
  module = {inputs, ...}: {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];
  };
in {
  flake.modules.darwin.system-base = module;
}
