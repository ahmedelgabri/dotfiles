{ stdenv, requireFile, unzip, lib }:

stdenv.mkDerivation rec {
  name = "pragmatapro-${version}";
  version = "0.828-2";

  src = requireFile rec {
    name = "PragmataPro${version}.zip";
    url = "file://path/to/${name}";
    sha256 = "19q6d0dxgd9k2mhr31944wpprks1qbqs1h5f400dyl5qzis2dji3";
    message = ''
      ${name} font not found in nix store, to add it run:
      $ nix-store --add-fixed sha256 ~/downloads/${name}'';
  };

  buildInputs = [ unzip ];
  phases = [ "unpackPhase" "installPhase" ];
  pathsToLink = [ "/share/fonts/truetype/" ];
  sourceRoot = ".";
  installPhase = ''
    install_path=$out/share/fonts/truetype
    mkdir -p $install_path
    find -name "PragmataPro*.ttf" -exec cp {} $install_path \;
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
