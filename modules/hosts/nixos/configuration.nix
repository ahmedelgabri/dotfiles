# NixOS host configuration (x86_64-linux)
{inputs, ...}: {
  flake.modules.nixos.nixos = {config, pkgs, ...}: {
    imports = with inputs.self.modules.nixos; [
      settings
      nix
      fonts
      git
    ];

    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.darwinModules.default
    ];

    networking.hostName = "nixos";

    # Import existing host-specific config from nix/hosts/nixos/
    imports = [../../nix/hosts/nixos];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      git
    ];
  };
}
