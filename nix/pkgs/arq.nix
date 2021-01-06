{ fetchurl, lib, stdenv, unzip, ... }:

with lib;
stdenv.mkDerivation rec {
  pname = "arq";
  version = "5.20";

  src = fetchurl {
    url = "https://www.arqbackup.com/download/arqbackup/Arq_${version}.zip";
    sha256 = "sha256-QZIQMdihQmd4Xa8R/GNpFrksWLBdSwootU4s5lPmDpE=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = "Arq.app";

  installPhase = ''
    mkdir -p "''${out}/Applications/${sourceRoot}"
    cp -R . "''${out}/Applications/${sourceRoot}"
  '';

  meta = {
    description = "Arq backs up your files. You control your data.";
    license = licenses.unfree;
    platforms = platforms.darwin;
  };
}
