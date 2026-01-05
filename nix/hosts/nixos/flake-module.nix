{inputs, ...}: {
  flake.modules.nixos.nixos = {config, pkgs, ...}: {
    imports =
      [
        inputs.home-manager.nixosModules.home-manager
        inputs.agenix.nixosModules.default
        ./_default.nix
      ]
      ++ (with inputs.self.modules.nixos; [
        user-options
        nix-daemon
        state-version
        home-manager-integration
        fonts
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
      ]);

    networking.hostName = "nixos";

    home-manager.users.${config.my.username}.imports = with inputs.self.modules.homeManager; [];
  };

  flake.nixosConfigurations =
    inputs.self.lib.mkNixos "x86_64-linux" "nixos";
}
