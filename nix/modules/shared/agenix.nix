{...}: {
  flake.sharedModules.agenix = {...}: {
    environment = {
      shellAliases = {
        agenix = "agenix -i ~/.ssh/agenix";
      };
    };
  };
}
