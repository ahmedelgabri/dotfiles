{ stdenv, python3Packages, newSrc }:

python3Packages.buildPythonApplication rec {
  name = "lookatme";
  version = "2.3.0";

  src = newSrc;

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

  meta = with stdenv.lib; {
    description = "An interactive, terminal-based markdown presenter";
    homepage = "https://github.com/d0c-s4vage/lookatme";
    license = licenses.mit;
  };
}
