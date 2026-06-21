let
  module = {
    generic =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          environment.systemPackages = with pkgs; [
            git
            git-wt
          ];

          my.user.packages = with pkgs; [
            delta
            hub
            tig
            exiftool
            gh
            gh-gfm-preview
          ];
        };
      };

    homeManager =
      {
        pkgs,
        lib,
        myConfig,
        ...
      }:
      with lib;
      {
        xdg.configFile = {
          "git/config-nix".text = ''
            ; ${myConfig.nix_managed}
            ; vim: ft=gitconfig

            [user]
            ${optionalString (myConfig.name != "") "  name = ${myConfig.name}"}
            ${optionalString (myConfig.email != "") "  email = ${myConfig.email}"}
            useconfigonly = true

            ${optionalString (myConfig.github_username != "") ''
              [github]
              	username = ${myConfig.github_username}''}

            [gpg]
            	program = vcs-gpg

            [diff "exif"]
            	textconv = ${lib.getExe pkgs.exiftool}

            ${optionalString pkgs.stdenv.isDarwin ''
              [diff "plist"]
              	textconv = plutil -convert xml1 -o -''}

            [include]
            	path = ${myConfig.hostConfigHome}/gitconfig
          '';

          "git" = {
            recursive = true;
            source = ../../../../config/git;
          };

          "tig" = {
            recursive = true;
            source = ../../../../config/tig;
          };
        };
      };
  };
in
{
  flake = {
    modules = {
      generic.git = module.generic;
      homeManager.git = module.homeManager;
    };
  };
}
