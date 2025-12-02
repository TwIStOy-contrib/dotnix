{
  config,
  pkgs,
  nix-ai-tools,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.opencode;
  originalOpencode = nix-ai-tools.opencode;
  openrouterApiKeyPath = config.age.secrets."openrouter-api-key".path;
  opencode = pkgs.writeShellScriptBin "opencode" ''
    export OPENROUTER_API_KEY="$(cat ${openrouterApiKeyPath})"
    ${originalOpencode}/bin/opencode "$@"
  '';

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    theme = "catppuccin";
    model = "anthropic/claude-sonnet-4.5";
    autoupdate = true;
    provider = {
      openrouter = {
        options = {
          baseURL = "https://ai-proxy.chatwise.app/openrouter";
          apiKey = "{env:OPENROUTER_API_KEY}";
        };
      };
    };
    plugin = ["opencode-skills"];
  };
in {
  options.dotnix.apps.opencode = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.opencode";
  };

  config = lib.mkIf cfg.enable {
    # Install opencode package
    environment.systemPackages = [
      opencode
    ];

    # setup opencode configs
    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile."opencode/opencode.json" = {
        text = builtins.toJSON opencodeConfig;
        force = true;
      };
    };
  };
}
