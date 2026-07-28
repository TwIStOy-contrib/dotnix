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

      # difftastic reads DFT_BACKGROUND (dark|light), which matches the
      # TERM_THEME probed in dotnix.apps.fish. That probe runs at mkOrder 700,
      # so it is already set before this default-order snippet. git-difftool
      # inherits the env from the interactive shell it's launched from.
      programs.fish.interactiveShellInit = ''
        if set -q TERM_THEME
            set -gx DFT_BACKGROUND "$TERM_THEME"
        end
      '';
    };
  };
}
