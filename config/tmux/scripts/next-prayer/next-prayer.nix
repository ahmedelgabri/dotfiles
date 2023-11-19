{ buildGo121Module }:

buildGo121Module rec {
  name = "next-prayer";
  version = "latest";

  vendorHash = null;

  src = ./.;

  ldflags = [ "-w" "-s" "-X=main.version=${version}" ];
}
