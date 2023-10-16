{ buildGo121Module }:

buildGo121Module rec {
  name = "next-prayer";
  version = "latest";

  vendorSha256 = null;

  src = ./.;

  ldflags = [ "-w" "-s" "-X=main.version=${version}" ];
}
