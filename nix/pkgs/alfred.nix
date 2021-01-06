{ fetchurl, lib, stdenv, undmg, ... }:

with lib;
stdenv.mkDerivation rec {
  pname = "alfred";
  version = "4.3_1205";

  src = fetchurl {
    url = "https://cachefly.alfredapp.com/Alfred_${version}.dmg";
    sha256 = "7KbokPc2thwznSDpDMubdBFBvfBetPdpWjcfI+zrbLQ=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = "Alfred 4.app";

  installPhase = ''
    mkdir -p "''${out}/Applications/Alfred 4.app"
    cp -R . "''${out}/Applications/Alfred 4.app"
  '';

  meta = {
    description =
      "Alfred is an award-winning app for macOS which boosts your efficiency with hotkeys, keywords, text expansion and more. Search your Mac and the web, and be more productive with custom actions to control your Mac.";
    license = licenses.unfree;
    platforms = platforms.darwin;
  };
}
