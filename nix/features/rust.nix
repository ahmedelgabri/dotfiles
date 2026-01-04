{inputs, ...}: let
  # The actual NixOS module for rust configuration
  rustModule = {
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.rust;
  in {
    options = with lib; {
      my.modules.rust = {
        enable = mkEnableOption ''
          Whether to enable rust module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        my.env = {
          RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
          CARGO_HOME = "$XDG_DATA_HOME/cargo";
        };
      };
  };
in {
  # Define modules for both darwin and nixos to import
  flake.modules.darwin.rust = rustModule;
  flake.modules.nixos.rust = rustModule;
}
