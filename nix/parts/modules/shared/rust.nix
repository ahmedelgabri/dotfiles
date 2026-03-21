let
  module = _: {
    config = {
      my.env = {
        RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
      };
    };
  };
in {
  flake.modules.generic.rust = module;
}
