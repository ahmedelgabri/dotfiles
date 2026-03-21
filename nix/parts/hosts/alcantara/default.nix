{inputs, ...}: let
  host = inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";

  hostConfiguration = {pkgs, ...}: {
    networking = {hostName = "alcantara";};

    my.user = {
      packages = with pkgs; [
        llm-agents.amp
        llm-agents.codex
        llm-agents.opencode
        llm-agents.pi
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
