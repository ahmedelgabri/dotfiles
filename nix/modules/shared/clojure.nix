{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.clojure;

in
{
  options = with lib; {
    my.modules.clojure = {
      enable = mkEnableOption ''
        Whether to enable clojure module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = {
        packages = with pkgs; [
          clojure
          leiningen
          joker
          # clj-kondo
        ];
      };
    };
}
