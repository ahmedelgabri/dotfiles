{inputs, ...}: let
  discordModule = {
    pkgs,
    lib,
    config,
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
in {
  flake.modules.darwin.discord = discordModule;
  flake.modules.nixos.discord = discordModule;
}
