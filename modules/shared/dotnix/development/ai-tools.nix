{
  config,
  pkgs-unstable,
  lib,
  ...
}: let
  cfg = config.dotnix.development.ai-tools;
in {
  options.dotnix.development.ai-tools = {
    enable = lib.mkEnableOption "Enable development AI tools";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs-unstable; [
      # Github Copilot CLI
      github-copilot-cli
      # Claude Code Cli
      claude-code
    ];
  };
}
