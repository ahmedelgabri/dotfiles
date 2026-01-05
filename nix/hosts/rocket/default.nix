{inputs, ...}: {
  flake.modules.darwin.rocket = {config, pkgs, ...}: {
    imports =
      [
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.agenix.darwinModules.default
      ]
      ++ (with inputs.self.modules.darwin; [
        user-options
        nix-daemon
        state-version
        home-manager-integration
        fonts
        defaults
        shell
        git
        vim
        tmux
        ssh
        gpg
        kitty
        ghostty
        yazi
        bat
        ripgrep
        mpv
        yt-dlp
        gui
        zk
        ai
        agenix
        misc
        node
        python
        go
        rust
        hammerspoon
        karabiner
      ]);

    networking.hostName = "rocket";
    ids.gids.nixbld = 30000;

    my = {
      username = "ahmedelgabri";
      email = "ahmed@miro.com";
      website = "https://miro.com";
      company = "Miro";
      devFolder = "dev";
      modules = {
        gpg.enable = true;
        mail = {
          enable = true;
          accounts = [
            {
              name = "Work";
              email = "ahmed@miro.com";
              service = "gmail.com";
              mbsync = {
                extra_exclusion_patterns = ''!"Version Control" !"Version Control/*" !GitHub !GitHub/* !"Inbox - CC" "!Inbox - CC/*" ![Gmail]* !Sent !Spam !Starred !Archive'';
              };
            }
          ];
        };
      };
      user.packages = with pkgs; [
        graph-easy
        graphviz
        nodePackages.mermaid-cli
        jira-cli-go
        git-filter-repo
        git-lfs
        git-sizer
        httpstat
        k9s
        lazydocker
        mise
      ];
    };

    homebrew = {
      casks = [
        "loom"
        "docker-desktop"
        "ngrok"
        "figma"
        "visual-studio-code"
        "google-chrome"
        "cursor"
        "claude-code"
        "superwhisper"
      ];

      brews = [
        "go-task"
        "jiratui"
      ];
    };

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "rocket";
}
