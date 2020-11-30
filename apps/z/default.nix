{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "z-${version}";
  version = "master";

  src = fetchFromGitHub {
    owner = "rupa";
    repo = "z";
    rev = "master";
    sha256 = "0ihs3m8czx2x735r968jl31vs47psbjqfarqpcn891wzd9ygzzm0";
  };

  dontBuild = true;

  installPhase = ''
    install -Dm 644 z.sh "$out/share/z.sh"
    install -Dm 644 z.1 "$out/share/man/man1/z.1"
    mkdir "$out/bin"
    cat > "$out/bin/z-share" <<EOF
      #!/bin/sh
      echo "$out/share/z.sh"
    EOF
    chmod +x "$out/bin/z-share"
  '';

  meta = with stdenv.lib; {
    description = "Tracks your most used directories, based on 'frecency'";
    homepage = "https://github.com/rupa/z";
    license = licenses.wtfpl;
  };
}
