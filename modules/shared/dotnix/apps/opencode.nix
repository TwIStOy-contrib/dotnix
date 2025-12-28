{
  config,
  nix-ai-tools,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.opencode;
  openrouterApiKeyPath = config.age.secrets."openrouter-api-key".path;
  kouriApiKeyPath = config.age.secrets."kouri-api-token".path;
  kouriOptions = {
    baseURL = "https://api.kourichat.com/v1";
    apiKey = "{file:${kouriApiKeyPath}}";
  };
  makeCost = input: output: {
    inherit input output;
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    theme = "catppuccin";
    model = "anthropic/claude-sonnet-4.5";
    autoupdate = true;
    provider = {
      openrouter = {
        options = {
          baseURL = "https://ai-proxy.chatwise.app/openrouter";
          apiKey = "{file:${openrouterApiKeyPath}}";
        };
      };
      kouri-openai-comp = {
        npm = "@ai-sdk/openai-compatible";
        options = kouriOptions;
        models = {
          "qwen3-coder" = {
            name = "Qwen 3 Coder";
            cost = makeCost 4 16;
          };
          "qwen3-coder-flash" = {
            name = "Qwen 3 Coder Flash";
            cost = makeCost 0.99 1.98;
          };
        };
      };
      kouri-openai = {
        npm = "@ai-sdk/openai";
        options = kouriOptions;
        models = {
          "gpt-5.1-codex-max" = {
            name = "GPT-5.1 Codex Max";
            cost = makeCost 5 20;
          };
          "gpt-5.1-codex-mini" = {
            name = "GPT-5.1 Codex Mini";
            const = makeCost 0.5 4;
          };
        };
      };
      kouri-anthropic = {
        npm = "@ai-sdk/anthropic";
        options = kouriOptions;
        models = {
          "claude-sonnet-4-5-20250929" = {
            name = "Claude Sonnet 4.5";
            cost = makeCost 9 45;
          };
        };
      };
    };
    plugin = [];
  };
in {
  options.dotnix.apps.opencode = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.opencode";
  };

  config = lib.mkIf cfg.enable {
    # Install opencode package
    environment.systemPackages = [
      nix-ai-tools.opencode
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
