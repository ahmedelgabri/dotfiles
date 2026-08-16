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
            tig
            exiftool
            gh
            gh-gfm-preview
          ];
        };
      };

    homeManager =
      {
        config,
        pkgs,
        lib,
        myConfig,
        ...
      }:
      with lib;
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/git;
            sourceRoot = "${myConfig.dotfilesDir}/config/git";
            targetRoot = "git";
          }
          // config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/tig;
            sourceRoot = "${myConfig.dotfilesDir}/config/tig";
            targetRoot = "tig";
          }
          // {
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

              ${optionalString pkgs.stdenv.hostPlatform.isDarwin ''
                [diff "plist"]
                	textconv = plutil -convert xml1 -o -''}

              [include]
              	path = ${myConfig.hostConfigHome}/gitconfig
            '';
          };

        home.activation = optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          # The launchd agents written by `git maintenance start` hardcode the
          # git binary's Nix store path; after a git bump + store GC they fail
          # with EX_CONFIG and background maintenance silently stops. Re-run it
          # on every rebuild so the agents point at the current package.
          gitMaintenance = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            repo=$(${lib.getExe pkgs.git} config --global --get-all maintenance.repo 2>/dev/null | while IFS= read -r p; do
              [ -d "$p" ] && { printf '%s' "$p"; break; }
            done)

            if [ -n "$repo" ]; then
              echo ":: -> Refreshing git maintenance launchd agents..."
              PATH="/bin:/usr/bin:$PATH" ${lib.getExe pkgs.git} -C "$repo" maintenance start --scheduler=launchctl \
                || echo ":: !! git maintenance start failed"
            fi
          '';
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
