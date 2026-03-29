let
  module = {config, ...}: let
    inherit (config.home-manager.users."${config.my.username}") xdg;
  in {
    config = {
      environment.variables = {
        RUSTUP_HOME = "${xdg.dataHome}/rustup";
        CARGO_HOME = "${xdg.dataHome}/cargo";
      };
    };
  };
in {
  flake.modules.generic.rust = module;
}
