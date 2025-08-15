{
  node = {
    path = ./node;
    description = "A simple template node/js/ts workflows using pnpm and fnm";
    welcomeText = ''Welcome to nix node template, using Volta and pnpm'';
  };
  deno = {
    path = ./deno;
    description = "A simple template for Deno";
    welcomeText = ''Welcome to Deno template'';
  };
  bun = {
    path = ./bun;
    description = "A simple template for Bun";
    welcomeText = ''Welcome to Bun template'';
  };
  python = {
    path = ./python;
    description = "A simple template for Python";
    welcomeText = ''Welcome to python project template'';
  };
  python-script = {
    path = ./python-script;
    description = "A simple template for one-off Python scripts";
    welcomeText = ''Welcome to python uv script mode template'';
  };
  go = {
    path = ./go;
    description = "A simple template for Go";
    welcomeText = ''Welcome to Go template'';
  };
  rust = {
    path = ./rust;
    description = "A simple template for Rust";
    welcomeText = ''Welcome to Rust template'';
  };
  default = {
    path = ./plain;
    description = "An empty flake template";
    welcomeText = ''Welcome to Plain template'';
  };
}
