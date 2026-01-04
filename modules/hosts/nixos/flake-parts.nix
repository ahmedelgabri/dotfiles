# NixOS flake-parts module
{inputs, ...}: {
  flake.nixosConfigurations =
    inputs.self.lib.mkNixos "x86_64-linux" "nixos";
}
