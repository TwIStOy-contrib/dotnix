{
  config,
  nix-ai-tools,
  lib,
  ...
}: let
  cfg = config.dotnix.development.ai-tools;
in {
  options.dotnix.development.ai-tools = {
    enable = lib.mkEnableOption "Enable development AI tools";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with nix-ai-tools; [
      # Github Copilot CLI
      copilot-cli
      # Claude Code Cli
      claude-code
      # Claude Code Router
      claude-code-router
      # Google Gemini CLI
      gemini-cli
    ];
  };
}
