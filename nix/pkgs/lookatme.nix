{ lib, python3Packages, source }:

python3Packages.buildPythonApplication rec {
  name = "lookatme";
  version = "2.3.0";

  src = source;

  checkInputs = with python3Packages; [ pytest ];
  # checkPhase = ''
  #   py.test tests
  # '';

  propagatedBuildInputs = with python3Packages; [
    click
    marshmallow
    mistune
    pygments
    pyyaml
    urwid
  ];

  meta = {
    description = "An interactive, terminal-based markdown presenter";
    homepage = "https://github.com/d0c-s4vage/lookatme";
    license = lib.licenses.mit;
  };
}
