self: super:

rec {
  neovim = self.callPackage ./pkgs/neovim.nix { };
}
