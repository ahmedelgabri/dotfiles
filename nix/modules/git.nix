{inputs, ...}: let
  gitModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.git;
  in {
    options = with lib; {
      my.modules.git = {
        enable = mkEnableOption ''
          Whether to enable git module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        environment.systemPackages = with pkgs; [git];

        my.user = {
          packages = with pkgs; [
            delta
            hub
            gh
            gh-dash
            gh-gfm-preview
            tig
            exiftool
            jujutsu
          ];
        };

        my.hm.file = {
          ".config/git/config-nix" = with config.my; {
            text = ''
              ; ${nix_managed}
              ; vim: ft=gitconfig

              [user]
              ${optionalString (name != "") "  name = ${name}"}
              ${optionalString (email != "") "  email = ${email}"}
              useconfigonly = true

              ${optionalString (github_username != "") ''
                [github]
                	username = ${github_username}''}

              [gpg]
              	program = ${lib.getExe pkgs.gnupg}

              [diff "exif"]
              	textconv = ${lib.getExe pkgs.exiftool}

              ${optionalString pkgs.stdenv.isDarwin ''
                [diff "plist"]
                	textconv = plutil -convert xml1 -o -''}

              [include]
              	path = ${hostConfigHome}/gitconfig
            '';
          };

          ".config/git" = {
            recursive = true;
            source = ../../config/git;
          };

          ".config/tig" = {
            recursive = true;
            source = ../../config/tig;
          };

          ".config/jj" = {
            recursive = true;
            source = ../../config/jj;
          };

          # Make this conditional per host config
          ".config/jj/conf.d/nix.toml" = with config.my; {
            text = ''
              # ${nix_managed}
              #:schema https://jj-vcs.github.io/jj/latest/config-schema.json


              --when.hostnames = ["${config.networking.hostName}"]

              [user]
              ${optionalString (name != "") "name = \"${name}\""}
              ${optionalString (email != "") "email = \"${email}\""}
            '';
          };
        };
      };
  };
in {
  flake.modules.darwin.git = gitModule;
  flake.modules.nixos.git = gitModule;
}
