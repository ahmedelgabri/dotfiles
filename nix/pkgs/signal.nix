{ fetchurl, lib, stdenv, undmg, ... }:

with lib;
stdenv.mkDerivation rec {
  pname = "signal";
  version = "1.39.4";

  src = fetchurl {
    url =
      "https://updates.signal.org/desktop/signal-desktop-mac-${version}.dmg";
    sha256 = "sha256-hpfRk7i88GTVTWsrS0+o+8KAaRnwvx4oCv4iBw0cJzY=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = "Signal.app";

  installPhase = ''
    mkdir -p "''${out}/Applications/${sourceRoot}"
    cp -R . "''${out}/Applications/${sourceRoot}"
  '';

  meta = {
    description =
      "Speak Freely. Say 'hello' to a different messaging experience. An unexpected focus on privacy, combined with all of the features you expect.";
    license = licenses.free;
    platforms = platforms.darwin;
  };
}
