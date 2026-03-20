let
  module = {
    darwin = {
      lib,
      config,
      ...
    }: {
      config = with lib; {
        homebrew.casks = ["discord"];
      };
    };

    nixos = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [discord];
      };
    };
  };
in {
  flake = {
    modules = {
      darwin.discord = module.darwin;
      nixos.discord = module.nixos;
    };
  };
}
