{inputs, ...}: let
  host = inputs.self.lib.mkDarwin "aarch64-darwin" "rocket";
  m = inputs.self.modules;
  hm = m.homeManager;

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
          nodePackages.mermaid-cli
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
    m.generic.system-common
    m.darwin.system-base
    m.darwin.defaults
    m.darwin.shell
    m.generic.git
    m.generic.jujutsu
    m.generic.ssh
    m.generic.bat
    m.generic.yazi
    m.generic.ripgrep
    m.generic.tmux
    m.generic.misc
    m.generic.node
    m.generic.go
    m.generic.rust
    m.generic.python
    m.generic.agenix
    m.darwin.vim
    m.darwin.gui
    m.generic.ai
    m.generic.gpg
    m.darwin.mail
    m.darwin.mpv
    m.darwin.kitty
    m.darwin.ghostty
    m.generic.zk
    m.darwin.discord
    m.generic."yt-dlp"
    ({config, ...}: {
      home-manager.users."${config.my.username}".imports = [
        hm.shell
        hm.ssh
        hm.git
        hm.bat
        hm.ripgrep
        hm.yazi
        hm.tmux
        hm.misc
        hm.python
        hm.jujutsu
        hm.vim
        hm.ai
        hm.gui
        hm.mail
        hm.gpg
        hm.zk
        hm.ghostty
        hm.kitty
        hm.mpv
        hm."yt-dlp"
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
