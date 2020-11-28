{
  imports = [
    ./settings
    ./macos
    ./mail
    ./gpg
    ./git
    ./kitty
    ./alacritty
    ./bat
    ./lf
    ./mpv
    ./newsboat
    ./ripgrep
    ./tmux
    ./tuir

    ./python
  ];

  my = {
    # git.enable = true;
    # mail = { enable = true; };
    # gpg.enable = true;
    # kitty.enable = true;
    # alacritty.enable = true;
    # bat.enable = true;
    # lf.enable = true;
    # mpv.enable = true;
    # newsboat.enable = true;
    # python.enable = true;
    # ripgrep.enable = true;
    # tmux.enable = true;
    # tuir.enable = true;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
