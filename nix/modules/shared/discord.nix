{...}: {
  flake.sharedModules.discord = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin isLinux;
  in {
    config = with lib;
      mkMerge [
        (mkIf isDarwin {
          homebrew.casks = ["discord"];
        })
        (mkIf isLinux {
          my.user = {packages = with pkgs; [discord];};
        })
      ];
  };
}
