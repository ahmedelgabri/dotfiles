{
  imports = [ ./settings ./macos ./mail ./gpg ./git ./kitty ./alacritty ./bat ];

  my = {
    git.enable = false;
    mail.enable = false;
    gpg.enable = false;
    kitty.enable = false;
    alacritty.enable = false;
    bat.enable = false;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
