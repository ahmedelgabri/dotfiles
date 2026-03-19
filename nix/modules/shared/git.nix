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
      environment.systemPackages = with pkgs; [git git-wt];

      my.user = {
        packages = with pkgs; [
          delta
          hub
          tig
          exiftool

          gh
          gh-dash
          # gh-enhance
          gh-gfm-preview
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
            	program = vcs-gpg

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
          source = ../../../config/git;
        };

        ".config/tig" = {
          recursive = true;
          source = ../../../config/tig;
        };

        ".config/gh-dash/config.yml" = mkIf (config.my.company == "") (let
          yamlFormat = pkgs.formats.yaml {};
          configFile = yamlFormat.generate "config.yml" {
            defaults = {
              prApproveComment = ":shipit:";
              preview = {
                open = true;
                width = 100;
              };
              layout = {
                prs = {
                  repoName = {
                    grow = true;
                    width = 10;
                    hidden = false;
                  };
                };
              };
              refetchIntervalMinutes = 10;
            };
            keybindings = {
              prs = [
                {
                  # Override the default merge command to squash
                  # https://github.com/dlvhdr/gh-dash/blob/2a7e017686ba6a05d8b9ebc4568b0a1600308dff/.gh-dash.yml#L52
                  key = "m";
                  name = "Admin force merge";
                  command = "gh pr merge --admin --squash --repo {{.RepoName}} {{.PrNumber}}";
                }
                {
                  key = "c";
                  command = "tmux new-window -c {{.RepoPath}} 'gh pr checkout {{.PrNumber}} && nvim -c \":CodeDiff {{.BaseRefName}}...{{.HeadRefName}}\"'";
                }
                {
                  key = "T";
                  command = "gh enhance -R {{.RepoName}} {{.PrNumber}}";
                }
                {
                  key = "v";
                  name = "approve";
                  command = "gh pr review --repo {{.RepoName}} --approve --body \"$(${pkgs.lib.getExe pkgs.gum} write --placeholder=Approval\\ Comment)\" {{.PrNumber}}";
                }
              ];
            };
            # configure where to locate repos when checking out PRs
            repoPaths = {
              # https://www.gh-dash.dev/configuration/repo-paths/
              # :owner/:repo: ~/src/github.com/:owner/:repo # template if you always clone github repos in a consistent location
            };
            theme = {
              ui = {
                table = {
                  compact = true;
                };
              };
            };
            pager = {
              diff = "delta --side-by-side";
            };
          };
        in {
          text = with config.my;
            lib.concatStringsSep "\n" [
              "# yaml-language-server: $schema=https://www.gh-dash.dev/schema.json"
              ''# ${nix_managed}''
              (builtins.readFile configFile)
            ];
        });
      };
    };
}
