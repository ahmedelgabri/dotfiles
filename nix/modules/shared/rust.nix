{...}: {
  flake.sharedModules.rust = {...}: {
    config = {
      my.env = {
        RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
      };
    };
  };
}
