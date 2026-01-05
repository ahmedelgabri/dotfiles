{inputs, ...}: let
  ghosttyModule = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin isLinux;
  in {
    config = with lib;
      mkMerge [
        (mkIf isDarwin {
          homebrew.casks = [
            "ghostty@tip"
          ];
        })
        (mkIf isLinux {
          my.user = {
            packages = with pkgs; [
              # Broken on Darwin that's why we have two branches
              ghostty
            ];
          };
        })
        {
          my = {
            # user = {
            #   packages = with pkgs; [
            #     ghostty
            #   ];
            # };
            hm.file = {
              ".config/ghostty" = {
                recursive = true;
                source = ../../config/ghostty;
              };
            };
          };
        }
      ];
  };
in {
  flake.modules.darwin.ghostty = ghosttyModule;
  flake.modules.nixos.ghostty = ghosttyModule;
}
