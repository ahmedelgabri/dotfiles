let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        environment.systemPackages = with pkgs; [git git-wt];

        my.user.packages = with pkgs; [
          delta
          hub
          tig
          exiftool
          gh
          gh-dash
          gh-gfm-preview
        ];
      };
    };

    homeManager = {
      pkgs,
      lib,
      myConfig,
      ...
    }: let
      yamlFormat = pkgs.formats.yaml {};
      ghDashConfig = yamlFormat.generate "config.yml" {
        defaults = {
          prApproveComment = ":shipit:";
          preview = {
            open = true;
            width = 100;
          };
          layout.prs.repoName = {
            grow = true;
            width = 10;
            hidden = false;
          };
          refetchIntervalMinutes = 10;
        };
        keybindings.prs = [
          {
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
        repoPaths = {};
        theme.ui.table.compact = true;
        pager.diff = "delta --side-by-side";
      };
    in
      with lib; {
        xdg.configFile =
          {
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
          }
          // optionalAttrs (myConfig.company == "") {
            "gh-dash/config.yml".text = concatStringsSep "\n" [
              "# yaml-language-server: $schema=https://www.gh-dash.dev/schema.json"
              "# ${myConfig.nix_managed}"
              (builtins.readFile ghDashConfig)
            ];
          };
      };
  };
in {
  flake = {
    modules = {
      generic.git = module.generic;
      homeManager.git = module.homeManager;
    };
  };
}
