{ pkgs, lib, config, inputs, ... }:

let

  cfg = config.my.modules.node;
in
{
  options = with lib; {
    my.modules.node = {
      enable = mkEnableOption ''
        Whether to enable node module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      # workaround for now see https://github.com/NixOS/nixpkgs/issues/145634
      homebrew.brews = [ "yarn" ];
      my = {
        env = rec {
          FNM_DIR = "$XDG_DATA_HOME/fnm";
          # NODE_VERSIONS = "$FNM_DIR/node-versions";
          # NODE_VERSION_PREFIX = "v";
        };

        user = {
          packages = with pkgs; [
            fnm
            # Hardcodes? $NODE & $npm_node_execpath to the version from nixpkgs
            # yarn
            # nodePackages.yarn
            nodePackages.svgo
          ];
        };

        hm.file = {
          # ".config/direnv/direnvrc" = {
          #   recursive = true;
          #   text = ''
          #     use_fnm() {
          #       fnm use --install-if-missing || fnm use default
          #     }'';
          # };
          ".npmrc" = with config.my; {
            text = ''
              # ${nix_managed}
              # vim:ft=conf
              ${lib.optionalString (email != "") "email=${email}"}
              init-license=MIT
              ${lib.optionalString (email != "") "init-author-email=${email}"}
              ${lib.optionalString (name != "") "init-author-name=${name}"}
              ${lib.optionalString (website != "") "init-author-url=${website}"}
              init-version=0.0.1
              ${builtins.readFile ../../../config/.npmrc}'';
          };
        };
      };
    };
}
