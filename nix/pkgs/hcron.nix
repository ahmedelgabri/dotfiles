{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.hcron = pkgs.callPackage ./hcron-package.nix {};
  };
}
