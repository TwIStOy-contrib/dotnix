{
  config,
  inputs,
  llm-agents,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotnix.development.ai-tools;
in {
  options.dotnix.development.ai-tools = {
    enable = lib.mkEnableOption "Enable development AI tools";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages =
      (with llm-agents; [
        # Github Copilot CLI
        copilot-cli
        # Claude Code Cli
        claude-code
      ])
      ++ [
        # Agent multiplexer for the terminal
        inputs.herdr.packages.${pkgs.system}.default
      ];
  };
}
