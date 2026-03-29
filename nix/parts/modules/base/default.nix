let
  module = {
    imports = [
      ./identity.nix
      ./user.nix
      ./home-manager.nix
      ./zsh-global-aliases.nix
    ];
  };
in {
  flake.modules.generic.base = module;
}
