{
  imports = [ ./settings ./macos ./mail ./gpg ./git ];
  my = {
    git.enable = false;
    mail.enable = false;
    gpg.enable = false;
    # macos.enable = pkgs.stdenv.isDarwin;
  };
}
