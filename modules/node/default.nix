{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.node;

in {
  options = with lib; {
    my.node = {
      enable = mkEnableOption ''
        Whether to enable node module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = {
        packages = with pkgs; [
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
                  ${builtins.readFile ./.npmrc}'';

              };
            };
          };
        };
      };
    };
}
