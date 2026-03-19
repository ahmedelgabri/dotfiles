{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.jujutsu;
in {
  options = with lib; {
    my.modules.jujutsu = {
      enable = mkEnableOption ''
        Whether to enable jujutsu module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        jujutsu
      ];

      my.hm.file = {
        ".config/jj" = {
          recursive = true;
          source = ../../../config/jj;
        };

        ".config/jj/conf.d/nix.toml" = with config.my; {
          text = ''
            # ${nix_managed}
            #:schema https://docs.jj-vcs.dev/latest/config-schema.json


            --when.hostnames = ["${config.networking.hostName}"]

            [user]
            ${optionalString (name != "") "name = \"${name}\""}
            ${optionalString (email != "") "email = \"${email}\""}

          '';
        };
      };
    };
}
