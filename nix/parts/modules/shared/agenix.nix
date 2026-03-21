let
  module = _: {
    config = {
      environment = {
        shellAliases = {
          agenix = "agenix -i ~/.ssh/agenix";
        };
      };
    };
  };
in {
  flake.modules.generic.agenix = module;
}
