let
  availableEnvs = ["default" "tesla" "cloud"];

  fixModuleName = name:
    if name == "default"
    then "_default.nix"
    else name + ".nix";

  varFor = name: env: let
    envFileName = fixModuleName env;
    filePath = ./${name}/envs/${envFileName};
    defaultPath = ./${name}/envs/_default.nix;
  in
    if builtins.pathExists filePath
    then import filePath
    else import defaultPath;

  # env-unrelated constants
  constants = import ./constants.nix;
in rec {
  inherit availableEnvs varFor;

  varsFor = env: {
    user = varFor "user" env;
    inherit constants;
  };

  allVars = builtins.listToAttrs (
    builtins.map (env: {
      name = env;
      value = varsFor env;
    })
    availableEnvs
  );
}
