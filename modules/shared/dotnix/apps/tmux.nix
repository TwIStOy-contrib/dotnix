{
  config,
  lib,
  dotnix-utils,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.tmux;
in {
  options.dotnix.apps.tmux = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.tmux";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.tmux = {
        enable = true;

        shell = "${pkgs-unstable.fish}/bin/fish";
        terminal = "xterm-kitty";
        mouse = true;
        historyLimit = 5000;
        prefix = "c-g";

        baseIndex = 1;

        extraConfig = ''
          set -as terminal-overrides ",xterm**:Tc"
          set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
          set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

          set -g set-clipboard on

          setw -g xterm-keys on
          set -s escape-time 1                      # faster command sequences
          set -sg repeat-time 600                   # increase repeat timeout
          set -s focus-events on

          setw -q -g utf8 on

          set -s extended-keys on
          set -as terminal-features 'xterm*:extkeys'

          setw -g pane-base-index 1     # make pane numbering consistent with windows

          setw -g automatic-rename on   # rename window to reflect current program
          set -g renumber-windows on    # renumber windows when a window is closed
          set -g set-titles on

          set -g display-panes-time 800 # slightly longer pane indicators display time
          set -g display-time 1000      # slightly longer status messages display time

          set -g status-interval 10     # redraw status line every 10 seconds

          # clear both screen and history
          bind -n C-l send-keys C-l \; run 'sleep 0.1' \; clear-history

          # activity
          set -g monitor-activity on
          set -g visual-activity off

          # find session
          bind C-f command-prompt -p find-session 'switch-client -t %%'

          # split current window horizontally
          bind - split-window -v
          # split current window vertically
          bind | split-window -h

          # pane navigation
          bind -r h select-pane -L  # move left
          bind -r j select-pane -D  # move down
          bind -r k select-pane -U  # move up
          bind -r l select-pane -R  # move right
          bind > swap-pane -D       # swap current pane with the next one
          bind < swap-pane -U       # swap current pane with the previous one

          # pane resizing
          bind -r H resize-pane -L 2
          bind -r J resize-pane -D 2
          bind -r K resize-pane -U 2
          bind -r L resize-pane -R 2

          # window navigation
          unbind n
          unbind p
          bind -r C-h previous-window # select previous window
          bind -r C-l next-window     # select next window
          bind Tab last-window        # move to last active window
        '';
      };
    };
  };
}
