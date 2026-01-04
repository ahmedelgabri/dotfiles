# Rocket host (aarch64-darwin)
{inputs, ...}: {
  flake.modules.darwin.rocket = {config, pkgs, ...}: {
    imports = with inputs.self.modules.darwin; [
      user-options
      nix-daemon
      state-version
      home-manager-integration
      fonts
      defaults
    ];

    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    # Host-specific configuration
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

    # Home-manager configuration for this host
    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [
      # Add home-manager modules here
    ];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "rocket";
}
