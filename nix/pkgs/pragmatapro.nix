{
  stdenvNoCC,
  requireFile,
  lib,
  pkgs,
}:
let
  requireArchive =
    archive: sha256:
    requireFile {
      name = archive;
      url = "file://path/to/${archive}";
      inherit sha256;
      message = ''
        ${archive} font not found in nix store, to add it run:
        $ nix-store --add-fixed sha256 /path/to/${archive}

        Did you change the file? maybe you need to update the sha256
        $ nix-hash --flat --base32 --type sha256 /path/to/${archive} | pbcopy'';
    };
in
stdenvNoCC.mkDerivation {
  name = "PragmataPro";
  dontBuild = true;
  dontConfigure = true;

  srcs = [
    (requireArchive "PragmataPro.zip" "09vpzcalcg2dih98jhgw879glvsgg0gsxy9si7l0zm7ksklh013p")
    (requireArchive "PragmataPro-Variable.zip" "01b0fx0gm7j9150gmxijb902p4wy0cj3k5x4msk2y0dfqxfrig5c")
  ];

  buildInputs = [ pkgs.unzip ];

  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  installPhase = ''
    install_path=$out/share/fonts/opentype
    mkdir -p $install_path
    find -name "PragmataPro*.otf" -exec cp {} $install_path \;

    truetype_path=$out/share/fonts/truetype
    mkdir -p $truetype_path
    find -name "PragmataPro*VF*.ttf" -exec cp {} $truetype_path \;
  '';

  meta = with lib; {
    homepage = "https://www.fsd.it/shop/fonts/pragmatapro/";
    description = ''
      PragmataPro™ is a condensed monospaced font optimized for screen,
      designed by Fabrizio Schiavi to be the ideal font for coding, math and engineering
    '';
    platforms = platforms.all;
    license = licenses.unfree;
  };
}
