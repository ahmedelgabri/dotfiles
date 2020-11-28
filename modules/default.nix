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

    ./python
  ];

  my = {
    git.enable = false;
    mail = { enable = false; };
    gpg.enable = false;
    kitty.enable = false;
    alacritty.enable = false;
    bat.enable = false;
    lf.enable = false;
    mpv.enable = false;
    newsboat.enable = false;
    python.enable = false;
    ripgrep.enable = false;
    tmux.enable = false;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
