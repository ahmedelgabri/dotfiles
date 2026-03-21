let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = ["discord"];
      };
    };

    nixos = {
      pkgs,
      lib,
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
