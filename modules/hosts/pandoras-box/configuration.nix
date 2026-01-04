# Pandoras-box host configuration (x86_64-darwin)
{inputs, ...}: {
  flake.modules.darwin.pandoras-box = {config, pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      settings
      nix
      fonts
      defaults
      git
    ];

    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    networking.hostName = "pandoras-box";

    # Import existing host-specific config from nix/hosts/
    imports = [../../nix/hosts/pandoras-box.nix];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      git
    ];
  };
}
