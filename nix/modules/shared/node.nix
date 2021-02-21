{ pkgs, lib, config, inputs, ... }:

with config.my;

let

  cfg = config.my.modules.node;
  xdg = config.home-manager.users.${username}.xdg;
  n = pkgs.callPackage ../../pkgs/n.nix { source = inputs.n; };

in {
  options = with lib; {
    my.modules.node = {
      enable = mkEnableOption ''
        Whether to enable node module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        # ############## Direnv & n
        N_PREFIX = "${xdg.dataHome}";
        NODE_VERSIONS = "${xdg.dataHome}/n/versions/node";
        NODE_VERSION_PREFIX = "";
      };

      users.users.${username} = {
        packages = with pkgs; [
          n
          nodejs # LTS
          nodePackages.npm
          (yarn.override { inherit nodejs; })
          nodePackages.svgo
        ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".npmrc" = {
                text = ''
                  # ${nix_managed}
                  # vim:ft=conf
                  ${lib.optionalString (email != "") "email=${email}"}
                  init-license=MIT
                  ${lib.optionalString (email != "")
                  "init-author-email=${email}"}
                  ${lib.optionalString (name != "") "init-author-name=${name}"}
                  ${lib.optionalString (website != "")
                  "init-author-url=${website}"}
                  init-version=0.0.1
                  ${builtins.readFile ../../../config/.npmrc}'';
              };
            };
          };
        };
      };
    };
}
