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

        "aicommit2"
        "claude-code-router"
        "codex"
        "hat"
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
        ])
        ++ (with pkgs-unstable; [
          angrr
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
