{
  pkgs-unstable,
  llm-agents,
}: let
  pkgs = pkgs-unstable;
  mkEnvExports = env:
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList
      (name: value: "export ${name}=${pkgs.lib.escapeShellArg (toString value)}")
      env
    );

  mkShellEnvExports = env:
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList
      (name: value: "export ${name}=\"${toString value}\"")
      env
    );

  mkWrappedProgram = {
    name,
    package,
    executable ? name,
    env ? {},
    shellEnv ? {},
  }:
    pkgs.writeShellScriptBin name ''
      ${mkEnvExports env}
      ${mkShellEnvExports shellEnv}
      exec ${package}/bin/${executable} "$@"
    '';
in {
  inherit mkWrappedProgram;

  wrappedPrograms = {
    opencode = mkWrappedProgram {
      name = "opencode";
      package = llm-agents.opencode;
      env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
    };
  };
}
