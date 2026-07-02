{
  config,
  lib,
  dotnix-utils,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: let
  inherit (dotnix-utils) enabled enableModules;
  cfg = config.dotnix.suits.development;
in {
  options.dotnix.suits.development = {
    enable = lib.mkEnableOption "Enable module dotnix.suits.development";
  };

  config = lib.mkIf cfg.enable {
    dotnix = {
      apps = enableModules [
        "atuin"
        "bat"
        "direnv"
        "gh"
        "git"
        "lazygit"
        "difftastic"

        "claude-code-router"
        "codex"
        "hat"
        "herdr"
        "moshi-hook"
        "opencode"
        "pi"
        "todoist"
      ];

      development = {
        build-tools = {
          enable = true;
          unstable = [
            "cmake"
            "just"
          ];
        };
        ai-tools = {
          enable = true;
        };
        languages = {
          all = enabled;
        };
      };

      hm.packages =
        (with pkgs; [
          rsync
          man-pages
          # angrr lives in stable nixpkgs (fish 4.2.1) — the pkgs-unstable
          # copy pulls fish 4.8.0, whose dropped create_manpage_completions.py
          # breaks home-manager's fish-completions build.
          angrr
        ])
        ++ (with pkgs-unstable; [
          net-tools
          eternal-terminal
        ])
        ++ (with inputs.dotvim.packages.${pkgs.system}; [
          default
        ]);
    };

    home-manager =
      dotnix-utils.hm.hmConfig {
      };
  };
}
