{ buildGoModule }:

buildGoModule rec {
  name = "next-prayer";
  version = "latest";

  vendorHash = null;

  src = ./.;

  ldflags = [ "-w" "-s" "-X=main.version=${version}" ];
}
