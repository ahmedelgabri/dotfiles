{
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  name = "hcron";
  version = "1.1.1";
  dontBuild = true;
  dontConfigure = true;

  # Upstream ships no arm64 builds; darwin_amd64 runs on Apple Silicon via
  # Rosetta, and Linux needs its own artifact (a Mach-O binary is an
  # exec-format error there).
  src =
    let
      platform = if stdenvNoCC.hostPlatform.isLinux then "linux_amd64" else "darwin_amd64";
      hashes = {
        linux_amd64 = "0xr0kvb2idswk6avp22h3nak1l607nlp7ga1qmnafy6g1xy13m9d";
        darwin_amd64 = "0p42691d0wy14wjbgy3rp2pcsn3xrni9fnw35wia6jrsha2w5z07";
      };
    in
    fetchurl {
      url = "https://github.com/lnquy/cron/releases/download/v${version}/cron_${version}_${platform}.tar.gz";
      sha256 = hashes.${platform};
    };

  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin

    cp cron $out/bin/hcron

    chmod +x $out/bin/hcron
  '';
}
