{
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
      homebrew.brews = ["transcrypt"];

      my.user = {
        packages = with pkgs; [
          # gitAndTools.transcrypt # old version
          difftastic
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
            	program = ${pkgs.gnupg}/bin/gpg

            [diff "exif"]
            	textconv = ${pkgs.exiftool}/bin/exiftool

            ${optionalString pkgs.stdenv.isDarwin ''
              [diff "plist"]
              	textconv = plutil -convert xml1 -o -''}

            [include]
            	path = ${hostConfigHome}/gitconfig
          '';
        };

        ".config/git" = {
          recursive = true;
          source = ../../../config/git;
        };

        ".config/tig" = {
          recursive = true;
          source = ../../../config/tig;
        };

        ".config/jj" = {
          recursive = true;
          source = ../../../config/jj;
        };

        ".config/jj/config.d/nix.toml" = with config.my; {
          text = ''
            # ${nix_managed}
            "$schema" = "https://jj-vcs.github.io/jj/prerelease/config-schema.json"

            [user]
            ${optionalString (name != "") "  name = \"${name}\""}
            ${optionalString (email != "") "  email = \"${email}\""}
          '';
        };
      };
    };
}
