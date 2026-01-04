{inputs, ...}: {
  flake.modules.darwin.alcantara = {config, pkgs, ...}: {
    imports =
      with inputs.self.modules.darwin; [
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
        mail
        discord
      ];

    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.agenix.darwinModules.default
    ];

    networking.hostName = "alcantara";

    my.user.packages = with pkgs; [
      amp-cli
      codex
      opencode
    ];

    homebrew.casks = [
      "jdownloader"
      "signal"
      "monodraw"
      "sony-ps-remote-play"
      "helium-browser"
    ];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "aarch64-darwin" "alcantara";
}
