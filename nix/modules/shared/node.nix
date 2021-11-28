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
      homebrew.brews = [ "yarn" "pnpm" ];
      my = {
        user = {
          packages = with pkgs; [
            nodePackages.svgo
          ];
        };

        hm.file = {
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
