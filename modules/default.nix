{
  imports =
    [ ./settings ./macos ./mail ./gpg ./git ./kitty ./alacritty ./bat ./lf ];

  my = {
    git.enable = false;
    mail.enable = false;
    gpg.enable = false;
    kitty.enable = false;
    alacritty.enable = false;
    bat.enable = false;
    lf.enable = false;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
