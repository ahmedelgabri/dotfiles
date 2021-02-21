{ pkgs, lib, config, ... }:

let

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

      my.user = {
        packages = with pkgs; [ rustup rust-analyzer-unwrapped rustc cargo ];
      };
    };
}
