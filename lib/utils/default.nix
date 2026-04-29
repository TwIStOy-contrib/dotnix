{
  inputs,
  dotnix-constants,
}: let
  moduleArgs =
    {
      inherit dotnix-constants;
    }
    // inputs;
in rec {
  path = import ./path.nix moduleArgs;

  hm = import ./hm.nix {inherit inputs dotnix-constants;};

  # shortcuts
  enabled = {
    enable = true;
  };

  enableModules = modules:
    builtins.listToAttrs (
      builtins.map (m: {
        name = m;
        value = enabled;
      })
      modules
    );
}
