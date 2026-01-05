{inputs, ...}: let
  rustModule = {
    lib,
    config,
    ...
  }: {
    config = {
      my.env = {
        RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
      };
    };
  };
in {
  flake.modules.darwin.rust = rustModule;
  flake.modules.nixos.rust = rustModule;
}
