{
  pkgs,
  config,
  llm-agents,
  lib,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.opencode;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
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
    autoupdate = false;
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

  # fetch claude skills repo
  claudeSkills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "69c0b1a0674149f27b61b2635f935524b6add202";
    sha256 = "sha256-pllFZoWRdtLliz/5pLWks0V9nKFMzeWoRcmFgu2UWi8=";
  };

  originalOpencode = llm-agents.opencode;
  opencode = pkgs.writeShellScriptBin "opencode" ''
    export NODE_TLS_REJECT_UNAUTHORIZED=0
    ${originalOpencode}/bin/opencode "$@"
  '';
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

      home = {
        file = {
          "${homeDir}/.opencode/scripts" = {
            source = ./scripts;
            recursive = true;
            force = true;
          };
          "${homeDir}/.opencode/command" = {
            source = ./command;
            recursive = true;
            force = true;
          };
          "${homeDir}/.opencode/skill/skill-creator" = {
            source = "${claudeSkills}/skills/skill-creator";
            recursive = true;
            force = true;
          };
        };
      };
    };
  };
}
