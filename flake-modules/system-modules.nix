{
  inputs,
  self,
  ...
}: {
  flake = {
    # Expose reusable NixOS/nix-darwin modules for other flakes to consume
    nixosModules = {
      # Individual module exports
      settings = import "${self}/nix/modules/shared/settings.nix";

      # Or export all shared modules as a single module
      default = import "${self}/nix/modules/shared";
    };

    darwinModules = {
      # Individual module exports
      settings = import "${self}/nix/modules/shared/settings.nix";

      # Or export all shared modules as a single module
      default = import "${self}/nix/modules/shared";
    };
  };
}
