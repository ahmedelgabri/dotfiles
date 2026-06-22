let
  module = {
    imports = [
      ./identity.nix
      ./user.nix
      ./home-manager.nix
    ];
  };
in
{
  flake.modules.generic.base = module;
}
