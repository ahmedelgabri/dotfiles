{ lib, buildGo118Module }:

buildGo118Module rec {
  name = "next-prayer";
  version = "latest";

  vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
  # vendorSha256 = lib.fakeSha256;

  src = ./.;

  ldflags = [ "-w" "-s" "-X=main.version=${version}" ];
}
