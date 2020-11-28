{
  imports = [ ./settings ./macos ./mail ./gpg ./git ./kitty ./alacritty ];
  my = {
    git.enable = false;
    mail.enable = false;
    gpg.enable = false;
    kitty.enable = false;
    alacritty.enable = false;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
