{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  llm-agents,
  ...
}: let
  cfg = config."dotnix-pkgs";

  mkEnvExports = env:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
      (name: value: "export ${name}=${lib.escapeShellArg (toString value)}")
      env
    );

  mkShellEnvExports = env:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
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

  openrouterApiKeyPath = config.age.secrets."openrouter-api-key".path;
in {
  options."dotnix-pkgs" = {
    enable =
      (lib.mkEnableOption "reusable dotnix wrapped packages")
      // {
        default = true;
      };

    wrappedPrograms = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = {};
      description = "Reusable wrapped programs provided by dotnix.";
    };
  };

  config = lib.mkIf cfg.enable {
    "dotnix-pkgs".wrappedPrograms = {
      codex = mkWrappedProgram {
        name = "codex";
        package = pkgs-unstable.codex;
        shellEnv.OPENROUTER_API_KEY = "$(cat ${openrouterApiKeyPath})";
      };

      opencode = mkWrappedProgram {
        name = "opencode";
        package = llm-agents.opencode;
        env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
      };
    };
  };
}
