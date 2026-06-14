{
  pkgs,
  config,
  lib,
  dotnix-utils,
  dotnix-constants,
  dotnix-pkgs,
  inputs,
  ...
}: let
  cfg = config.dotnix.apps.opencode;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  hm-dag = inputs.home-manager.lib.hm.dag;
  openrouterApiKeyPath = config.age.secrets."openrouter-api-key".path;
  zAiApiKeyPath = config.age.secrets."z-ai-api-key".path;
  deepseekApiKeyPath = config.age.secrets."deepseek-api-key".path;
  inferenceTwistoyApiKeyPath = config.age.secrets."inference-twistoy-api-key".path;
  dotcodeMemoryDbUrlPath = config.age.secrets."dotcode-memory-db-url".path;

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    provider = {
      openrouter = {
        options = {
          baseURL = "https://ai-proxy.chatwise.app/openrouter";
          apiKey = "{file:${openrouterApiKeyPath}}";
        };
      };
      zai-coding-plan = {
        options = {
          apiKey = "{file:${zAiApiKeyPath}}";
        };
      };
      deepseek = {
        options = {
          apiKey = "{file:${deepseekApiKeyPath}}";
        };
      };
      inference-twistoy = {
        options = {
          apiKey = "{file:${inferenceTwistoyApiKeyPath}}";
        };
      };
    };
    mcp = {
      web-search-prime = {
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        headers = {
          Authorization = "Bearer {file:${zAiApiKeyPath}}";
        };
      };
      web-reader = {
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
        headers = {
          Authorization = "Bearer {file:${zAiApiKeyPath}}";
        };
      };
    };
    plugin = ["${homeDir}/dotcode/plugin/dist/dotcode.js"];
  };

  tuiConfig = {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
    plugin = ["${homeDir}/dotcode/plugin/dist/dotcode-tui.js"];
  };

  # fetch claude skills repo
  claudeSkills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "69c0b1a0674149f27b61b2635f935524b6add202";
    sha256 = "sha256-pllFZoWRdtLliz/5pLWks0V9nKFMzeWoRcmFgu2UWi8=";
  };

  opencode = dotnix-pkgs.wrapped-programs.opencode;
in {
  options.dotnix.apps.opencode = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.opencode";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      opencode
    ];

    # setup opencode configs
    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile."opencode/opencode.json" = {
        text = builtins.toJSON opencodeConfig;
        force = true;
      };

      xdg.configFile."opencode/tui.json" = {
        text = builtins.toJSON tuiConfig;
        force = true;
      };

      xdg.configFile."opencode/plugins" = {
        source = ./plugins;
        recursive = true;
        force = true;
      };

      xdg.configFile."dotcode/config.toml" = {
        text = ''
          [database]
          memory_url = "{file:${dotcodeMemoryDbUrlPath}}"
        '';
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

      home.activation.setup-dotcode = hm-dag.entryAfter ["linkGeneration"] ''
        # activation runs with a minimal PATH (home.path only); expose git+ssh
        # so `git clone git@...` can fork ssh.
        export PATH="${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.coreutils}/bin:$PATH"
        if [ ! -d "${homeDir}/dotcode" ]; then
          $DRY_RUN_CMD git clone git@github.com:TwIStOy/dotcode.git "${homeDir}/dotcode"
        fi
        if [ ! -f "${homeDir}/dotcode/plugin/dist/dotcode.js" ]; then
          $DRY_RUN_CMD ${pkgs.bun}/bin/bun install --cwd "${homeDir}/dotcode/plugin"
          $DRY_RUN_CMD ${pkgs.bun}/bin/bun run --cwd "${homeDir}/dotcode/plugin" build
        fi
      '';
    };
  };
}
