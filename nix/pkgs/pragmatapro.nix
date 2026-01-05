{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.pragmatapro = pkgs.callPackage ./pragmatapro-package.nix {};
  };
}
