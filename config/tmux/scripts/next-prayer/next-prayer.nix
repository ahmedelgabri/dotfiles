{buildGoModule}:
buildGoModule rec {
  name = "next-prayer";
  version = "latest";

  vendorHash = "sha256-3zBA+EYTj4V5/SQKYR0PuCjMOd2bYrjeA+6nKV4Qlj4=";

  src = ./.;

  ldflags = ["-w" "-s" "-X=main.version=${version}"];
}
