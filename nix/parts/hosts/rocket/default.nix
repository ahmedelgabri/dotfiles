{inputs, ...}: let
  host = inputs.self.lib.mkDarwin "aarch64-darwin" "rocket";

  hostConfiguration = {pkgs, ...}: {
    networking = {hostName = "rocket";};
    ids.gids.nixbld = 30000;

    my = {
      username = "ahmedelgabri";
      email = "ahmed@miro.com";
      website = "https://miro.com";
      company = "Miro";
      devFolder = "dev";
      modules = {
        mail = {
          accounts = [
            {
              name = "Work";
              email = "ahmed@miro.com";
              service = "gmail.com";
              mode = "remote";
              mbsync = {
                extra_exclusion_patterns = ''!"Version Control" !"Version Control/*" !GitHub !GitHub/* !"Inbox - CC" "!Inbox - CC/*" ![Gmail]* !Sent !Spam !Starred !Archive'';
              };
            }
          ];
        };
      };
      user = {
        packages = with pkgs; [
          graph-easy
          graphviz
          mermaid-cli
          jira-cli-go
          git-filter-repo
          git-lfs
          git-sizer
          httpstat
          k9s
          lazydocker
          llm-agents.gemini-cli
          entr
        ];
      };
    };

    homebrew = {
      taps = [
        "atlassian-labs/acli"
      ];

      casks = [
        "loom"
        "docker-desktop"
        "ngrok"
        "figma"
        "visual-studio-code"
        "google-chrome"
        "cursor"
      ];

      brews = [
        "acli"
      ];
    };
  };

  systemImports = [
    (inputs.self.lib.mkFeatureModule "darwin" {
      features = [
        "system-base"
        "defaults"
        "shell"
        "git"
        "jujutsu"
        "ssh"
        "bat"
        "yazi"
        "ripgrep"
        "tmux"
        "misc"
        "node"
        "go"
        "rust"
        "python"
        "agenix"
        "vim"
        "gui"
        "ai"
        "gpg"
        "mail"
        "mpv"
        "kitty"
        "ghostty"
        "zk"
        "discord"
        "yt-dlp"
        "bun"
      ];
    })
    hostConfiguration
  ];
in {
  flake.modules.darwin.rocket = {
    imports = systemImports;
  };

  flake = {
    darwinConfigurations = host;
    rocket = host.rocket.system;
  };
}
