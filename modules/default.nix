{
  imports = [ ./settings ./macos ./mail ./gpg ./git ./kitty ];
  my = {
    git.enable = false;
    mail.enable = false;
    gpg.enable = false;
    kitty.enable = false;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
