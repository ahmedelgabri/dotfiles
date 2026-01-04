# NixOS host (x86_64-linux)
{inputs, ...}: {
  flake.modules.nixos.nixos = {config, pkgs, ...}: {
    imports = with inputs.self.modules.nixos; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      git
    ];

    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.darwinModules.default
    ];

    networking.hostName = "nixos";

    # Import existing host-specific config from nix/hosts/nixos/
    imports = [../nix/hosts/nixos];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      git
    ];
  };

  flake.nixosConfigurations =
    inputs.self.lib.mkNixos "x86_64-linux" "nixos";
}
