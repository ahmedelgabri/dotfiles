{ lib, buildGo121Module, source }:

buildGo121Module rec {
  pname = "zk";
  version = "main";

  # TODO is it possibe to pin the hash in flake.lock?
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-23m0fHYJl3X2uHCFnMYID9umTjZvGFoOKTtRrerlWKg=";

  doCheck = false;

  src = source;

  CGO_ENABLED = 1;

  tags = [ "fts5" ];

  ldflags = [ "-X=main.Version=${version}" "-X=main.Build=${version}" ];

  meta = with lib; {
    license = licenses.gpl3;
    description = "A zettelkasten plain text note-taking assistant";
    homepage = "https://github.com/mickael-menu/zk";
  };
}
