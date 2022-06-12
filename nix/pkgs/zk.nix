{ lib, fetchFromGitHub, buildGo118Module, source }:

buildGo118Module rec {
  pname = "zk";
  version = "main";

  # TODO is it possibe to pin the hash in flake.lock?
  # This should be doable with https://github.com/tweag/gomod2nix
  vendorSha256 = "sha256-11GzI3aEhKKTiULoWq9uIc66E3YCrW/HJQUYXRhCaek=";

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
