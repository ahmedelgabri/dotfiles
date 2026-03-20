{inputs, ...}: let
  host = inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
  m = inputs.self.modules;
  hm = m.homeManager;

  hostConfiguration = {pkgs, ...}: {
    networking = {hostName = "alcantara";};

    my.user = {
      packages = with pkgs; [
        llm-agents.amp
        llm-agents.codex
        llm-agents.opencode
        colima
        docker
        podman
      ];
    };

    homebrew = {
      casks = [
        # "arq" # I need a specific version so I will handle it myself.
        "jdownloader"
        "signal"
        "monodraw"
        "sony-ps-remote-play"
        "helium-browser"
      ];

      # Requires to be logged in to the AppStore
      # Cleanup doesn't work automatically if you add/remove to list
      # masApps = {
      #   Guidance = 412759995;
      #   Dato = 1470584107;
      #   "Day One" = 1055511498;
      #   Tweetbot = 1384080005;
      #   Todoist = 585829637;
      #   Sip = 507257563;
      #   Irvue = 1039633667;
      #   Telegram = 747648890;
      # };
    };
  };

  systemImports = [
    m.darwin.system-common
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
  flake.modules.darwin.alcantara = {
    imports = systemImports;
  };

  flake = {
    darwinConfigurations = host;
    alcantara = host.alcantara.system;
  };
}
