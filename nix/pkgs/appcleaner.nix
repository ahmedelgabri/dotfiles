{ fetchurl, lib, stdenv, unzip, ... }:

with lib;
stdenv.mkDerivation rec {
  pname = "appcleaner";
  version = "3.5.1";

  src = fetchurl {
    url = "https://freemacsoft.net/downloads/AppCleaner_${version}.zip";
    sha256 = "ZLcHtIQUWDALAjdNS5Ws/tJ+RTuhu/UPfR/E+w8tG3A=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = "AppCleaner.app";

  installPhase = ''
    mkdir -p $out/Applications/AppCleaner.app
    cp -R . $out/Applications/AppCleaner.app
  '';

  meta = {
    description =
      "A small application which allows you to thoroughly uninstall unwanted apps";
    homepage = "https://freemacsoft.net/appcleaner";
    license = licenses.unfree;
    platforms = platforms.darwin;
  };
}
