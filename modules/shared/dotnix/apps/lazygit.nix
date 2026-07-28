{
  config,
  lib,
  dotnix-utils,
  pkgs,
  ...
}: let
  cfg = config.dotnix.apps.lazygit;

  # delta has no background detection that's safe in lazygit's pager context:
  # its stdout is piped to lazygit, so --detect-dark-light=auto won't query the
  # terminal, and =always races with lazygit for tty input. Drive it from
  # TERM_THEME (probed in dotnix.apps.fish) via a wrapper instead. Falls back
  # to dark when TERM_THEME is unset.
  deltaPager = pkgs.writeShellScriptBin "lazygit-delta" ''
    exec delta "--''${TERM_THEME:-dark}" --paging=never "$@"
  '';
in {
  options.dotnix.apps.lazygit = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.lazygit";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [deltaPager];

    home-manager = dotnix-utils.hm.hmConfig {
      programs.lazygit = {
        enable = true;
        package = pkgs.lazygit;
        settings = {
          # lazygit's theme uses ANSI color names (green/blue/cyan/...), no hex,
          # so it adapts automatically via the terminal's (catppuccin) palette.
          gui = {
            mouseEvents = true;
            nerdFontsVersion = "3";
            border = "single";
          };
          notARepository = "skip";
          git = {
            parseEmoji = true;
            autoFetch = true;
            overrideGpg = true;
            commit = {
              signOff = true;
            };
            pagers = [
              {
                pager = "lazygit-delta";
              }
              {
                # difft picks up DFT_BACKGROUND (set in dotnix.apps.fish) from
                # the env lazygit inherits.
                externalDiffCommand = "difft --color=always";
              }
            ];
          };
        };
      };
    };
  };
}
