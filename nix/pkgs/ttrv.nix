{ lib, source, python3Packages }:

with python3Packages;
buildPythonApplication rec {
  pname = "ttrv";
  version = "1.27.3";

  src = source;

  # Tests try to access network
  doCheck = false;

  checkPhase = ''
    py.test
  '';

  checkInputs = [ coverage coveralls docopt mock pylint pytest vcrpy ];

  propagatedBuildInputs = [ beautifulsoup4 decorator kitchen requests ];

  meta = with lib; {
    description =
      "A text-based interface (TUI) to view and interact with Reddit from your terminal.";
    homepage = "https://github.com/tildeclub/ttrv";
    license = licenses.mit;
    maintainers = with maintainers; [ filalex77 matthiasbeyer ];
  };
}
