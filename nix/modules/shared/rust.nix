{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.rust;
  xdg = config.home-manager.users.${config.my.username}.xdg;

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
      environment.variables = {
        RUSTUP_HOME = "${xdg.dataHome}/rustup";
        CARGO_HOME = "${xdg.dataHome}/cargo";
      };

      my.user = {
        packages = with pkgs; [ rustup rust-analyzer-unwrapped rustc cargo ];
      };
    };
}
