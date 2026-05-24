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

  llmApiKeys = {
    ZAI_API_KEY = "$(cat /run/agenix/z-ai-api-key)";
    DEEPSEEK_API_KEY = "$(cat /run/agenix/deepseek-api-key)";
    OPENROUTER_API_KEY = "$(cat /run/agenix/openrouter-api-key)";
  };
in {
  inherit mkWrappedProgram llmApiKeys;

  wrappedPrograms = {
    opencode = mkWrappedProgram {
      name = "opencode";
      package = llm-agents.opencode;
      env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
      shellEnv = llmApiKeys;
    };

    pi = mkWrappedProgram {
      name = "pi";
      package = llm-agents.pi;
      shellEnv = llmApiKeys;
    };
  };
}
