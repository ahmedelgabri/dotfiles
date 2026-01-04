{inputs, ...}: {
  flake.modules.darwin.pandoras-box = {config, pkgs, ...}: {
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

    networking.hostName = "pandoras-box";

    homebrew.casks = [
      # "arq" # I need a specific version so I will handle it myself.
      "transmit"
      "jdownloader"
      "brave-browser"
      "signal"
    ];

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [];
  };

  flake.darwinConfigurations =
    inputs.self.lib.mkDarwin "x86_64-darwin" "pandoras-box";
}
