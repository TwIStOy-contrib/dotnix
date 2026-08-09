{
  config,
  lib,
  dotnix-utils,
  pkgs,
  pkgs-unstable,
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
        # Use the same channel (nixos-unstable) as the lazygit bundled in
        # `ne` (dotvim's toggleterm/snacks). lazygit shows a hardcoded
        # "Breaking Changes" popup whenever its running version is newer than
        # the `lastversion` recorded in state.yml; if the two sources drift
        # (stable 0.56.x vs unstable 0.6x), every switch between `lg` and ne
        # re-triggers it. Both channels land above the latest breaking-change
        # entry (0.62.0), so aligning them kills the popup permanently. See
        # lazygit pkg/gui/gui.go showBreakingChangesMessage().
        package = pkgs-unstable.lazygit;
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
            diffRenderers = [
              {
                command = "lazygit-delta";
              }
              {
                command = "difft --color=always";
                type = "extDiff";
              }
            ];
          };
        };
      };
    };
  };
}
