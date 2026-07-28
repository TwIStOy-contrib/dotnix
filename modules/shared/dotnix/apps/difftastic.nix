{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.difftastic;
in {
  options.dotnix.apps.difftastic = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.difftastic";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.difftastic = {
        enable = true;
        git.enable = true;
      };

      # difftastic reads DFT_BACKGROUND (dark|light) = TERM_THEME. Follow it via
      # an --on-variable handler (TERM_THEME is driven by fish's
      # fish_terminal_color_theme, see dotnix.apps.fish). git-difftool inherits
      # the env from the interactive shell it's launched from.
      programs.fish.interactiveShellInit = ''
        function _dotnix_sync_dft_background --on-variable TERM_THEME
            if set -q TERM_THEME
                set -gx DFT_BACKGROUND "$TERM_THEME"
            end
        end
        _dotnix_sync_dft_background
      '';
    };
  };
}
