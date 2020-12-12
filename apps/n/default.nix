{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "n-${version}";
  version = "master";

  src = fetchFromGitHub {
    owner = "tj";
    repo = "n";
    rev = "master";
    sha256 = "0rl1n1v19j0j8kyk7pb3zsglrwx2jrnpfsjvqjhb2z5pj2i6gs76";
  };

  dontBuild = true;

  installPhase = ''
    PREFIX=$out make install
  '';

  meta = with stdenv.lib; {
    description = "Node version management";
    homepage = "https://github.com/tj/n";
    license = licenses.mit;
  };
}
