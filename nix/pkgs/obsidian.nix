{ fetchurl, lib, stdenv, undmg, ... }:

with lib;
stdenv.mkDerivation rec {
  pname = "obsidian";
  version = "0.10.6";

  src = fetchurl {
    url =
      "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.dmg";
    sha256 = "sha256-uFbRJQ585/c8pPKeJ3mkSWIhGtuQjOcCaO+Qh4XitmQ=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = "Obsidian.app";

  installPhase = ''
    mkdir -p "''${out}/Applications/${sourceRoot}"
    cp -R . "''${out}/Applications/${sourceRoot}"
  '';

  meta = {
    description =
      "A second brain, for you, forever. Obsidian is a powerful knowledge base that works on top of a local folder of plain text Markdown files.";
    license = licenses.unfree;
    platforms = platforms.darwin;
  };
}
