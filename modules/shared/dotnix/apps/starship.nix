{
  config,
  pkgs,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.starship;

  theme-catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "starship";
    rev = "e99ba6b210c0739af2a18094024ca0bdf4bb3225";
    sha256 = "sha256-1w0TJdQP5lb9jCrCmhPlSexf0PkAlcz8GBDEsRjPRns=";
  };

  toml = pkgs.formats.toml {};

  commonSettings = {
    character = {
      success_symbol = "[](bold green)";
      error_symbol = "[](bold red)";
    };
    cmd_duration = {
      disabled = true;
    };
    git_branch = {
      symbol = " ";
      ignore_branches = ["master" "main"];
    };
    git_metrics = {
      disabled = false;
      ignore_submodules = true;
    };
    lua = {
      version_format = "v\${major}.\${minor}";
    };
    nix_shell = {
      heuristic = true;
    };
  };

  # Each catppuccin theme TOML only defines its own
  # [palettes.catppuccin_<flavor>] table; pick the one for the requested
  # flavor and select it as the active palette.
  withFlavor = flavor:
    commonSettings
    // (lib.importTOML "${theme-catppuccin}/themes/${flavor}.toml")
    // {palette = "catppuccin_${flavor}";};
in {
  options.dotnix.apps.starship = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.starship";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.starship = {
        enable = true;

        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;

        # starship.toml is the dark (default/fallback) variant. The light
        # variant lives in starship-light.toml and is selected via
        # STARSHIP_CONFIG in the fish init below.
        settings = withFlavor "mocha";
      };

      # starship has no native dark/light support (starship/starship#6991);
      # select the palette file based on TERM_THEME (see dotnix.apps.fish).
      programs.fish.interactiveShellInit = ''
        if test "$TERM_THEME" = "light"
            set -gx STARSHIP_CONFIG ~/.config/starship-light.toml
        else
            set -e STARSHIP_CONFIG
        end
      '';

      xdg.configFile."starship-light.toml".source = toml.generate "starship-light.toml" (withFlavor "latte");
    };
  };
}
