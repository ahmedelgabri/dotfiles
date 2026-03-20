let
  module = {
    imports = [
      ./identity.nix
      ./user.nix
      ./home-manager.nix
      ./env.nix
    ];
  };
in {
  flake.modules.generic.base = module;
}
