_: {
  imports = [
    ./base/common.nix
  ];

  flake.modules = {
    darwin.system-base = import ./base/darwin.nix;
    nixos.system-base = import ./base/nixos.nix;
  };
}
