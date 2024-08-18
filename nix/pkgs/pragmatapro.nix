{ stdenvNoCC, requireFile, lib, pkgs }:

stdenvNoCC.mkDerivation rec {
  name = "PragmataPro${version}";
  version = "0.830";
  dontBuild = true;
  dontConfigure = true;

  src = requireFile {
    url = "file://path/to/${name}.zip";
    sha256 = "0cna4wavnhnb8j8vg119ap8mqkckx04z2gms2hsz4daywc51ghr8";
    message = ''
      ${name} font not found in nix store, to add it run:
      $ nix-store --add-fixed sha256 /path/to/${name}.zip

      Did you change the file? maybe you need to update the sha256
      $ nix-hash --flat --base32 --type sha256 /path/to/${name}.zip'';
  };

  buildInputs = [ pkgs.unzip ];

  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  installPhase = ''
    install_path=$out/share/fonts/opentype
    mkdir -p $install_path

    find -name "PragmataPro*.otf" -exec cp {} $install_path \;
  '';

  meta = with lib; {
    homepage = "https://www.fsd.it/shop/fonts/pragmatapro/";
    description = ''
      PragmataPro™ is a condensed monospaced font optimized for screen,
      designed by Fabrizio Schiavi to be the ideal font for coding, math and engineering
    '';
    platforms = platforms.all;
    licence = licences.unfree;
  };
}
