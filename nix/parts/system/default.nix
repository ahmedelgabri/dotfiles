_: {
  flake.modules = {
    generic.system-common = import ./base/common.nix;

    darwin.system-base = import ./base/darwin.nix;

    nixos.system-common = import ./base/nixos-common.nix;
    nixos.system-base = import ./base/nixos.nix;
  };
}
