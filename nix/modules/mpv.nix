{inputs, ...}: let
  mpvModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin;
  in {
    config = with lib;
      mkMerge [
        (mkIf isDarwin {
          homebrew.casks = ["iina"];
        })

        {
          my.user = {packages = with pkgs; [mpv];};
          my.hm.file = {
            ".config/mpv" = {
              recursive = true;
              source = ../../config/mpv;
            };
          };
        }
      ];
  };
in {
  flake.modules.darwin.mpv = mpvModule;
  flake.modules.nixos.mpv = mpvModule;
}
