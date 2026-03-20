{
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  imports = [
    ../flake-parts/darwinConfigurations-fix.nix
    ../flake-parts/modules.nix
    ../flake-parts/lib.nix
    ../modules/default.nix
    ../system/default.nix
    ../hosts/rocket/default.nix
    ../hosts/alcantara/default.nix
    ../hosts/nixos/default.nix
    ../outputs/overlays.nix
    ../outputs/pkgs.nix
    ../outputs/formatter.nix
    ../outputs/devshells.nix
    ../outputs/apps.nix
    ../outputs/templates.nix
  ];
}
