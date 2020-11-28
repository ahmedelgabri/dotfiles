{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.git;

in {
  options = with lib; {
    my.git = {
      enable = mkEnableOption ''
        Whether to enable git module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ git ];

      users.users.${username} = {
        packages = with pkgs; [
          gitAndTools.transcrypt
          # gitAndTools.diff-so-fancy
          gitAndTools.delta
          gitAndTools.hub
          gitAndTools.gh
          gitAndTools.tig
          universal-ctags
          exiftool
        ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/git/config" = {
                text = ''
                  ; ${nix_managed}
                  ; vim: ft=gitconfig

                  [user]
                  ${optionalString (name != "") "	name = ${name}"}
                  ${optionalString (email != "") "	email = ${email}"}
                  	useconfigonly = true

                  ${optionalString (github_username != "") ''
                    [github]
                    	username = ${github_username}''}

                  [gpg]
                  	program = ${pkgs.gnupg}/bin/gpg

                  [diff "exif"]
                  	textconv = ${pkgs.exiftool}/bin/exiftool

                  ${optionalString (pkgs.stdenv.isDarwin) ''
                    [diff "plist"]
                      textconv = plutil -convert xml1 -o -''}

                  ${builtins.readFile ./config}'';
              };

              ".config/git/ignore" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ./ignore}'';
              };

              ".config/git/attributes" = {
                text = ''
                  # ${nix_managed}
                  ${builtins.readFile ./attributes}'';
              };

              ".config/git/hooks" = { source = ./hooks; };
              ".config/tig/config" = { source = ./tigrc; };
            };
          };
        };
      };
    };
}