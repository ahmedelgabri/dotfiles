{ fetchurl, stdenv, }:

stdenv.mkDerivation rec {
  name = "hcron";
  version = "1.1.1";

  src = fetchurl {
    url = "https://github.com/lnquy/cron/releases/download/v${version}/cron_${version}_darwin_amd64.tar.gz";
    sha256 = "0p42691d0wy14wjbgy3rp2pcsn3xrni9fnw35wia6jrsha2w5z07";
  };

  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  phases = [ "unpackPhase" "installPhase" "patchPhase" ];

  installPhase = ''
    mkdir -p $out/bin

    cp cron $out/bin/hcron

    chmod +x $out/bin/hcron
  '';
}
