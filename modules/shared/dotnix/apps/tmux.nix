{
  config,
  lib,
  dotnix-utils,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.tmux;

  # Pin catppuccin/tmux v2.x for the modern @catppuccin_flavor / status-module API.
  # nixpkgs may lag (or still ship a pre-v2 snapshot); keep this in sync with the
  # version validated on the work machine (~/.config/tmux).
  tmux-catppuccin = pkgs-unstable.tmuxPlugins.mkTmuxPlugin {
    pluginName = "catppuccin";
    version = "2.3.0";
    src = pkgs-unstable.fetchFromGitHub {
      owner = "catppuccin";
      repo = "tmux";
      rev = "v2.3.0";
      hash = "sha256-3CJRQCgS8NAN7vOLBjNGiHbGXTIrIyY/FLmfZrXcEYc=";
    };
  };
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

        # HM order: plugin.extraConfig → run-shell <rtp> → (later) programs.tmux.extraConfig.
        # Pre-load options only here; status/message overrides belong in extraConfig below.
        plugins = [
          {
            plugin = tmux-catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavor "mocha"
              set -g @catppuccin_window_status_style "rounded"
            '';
          }
        ];

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

          set -sg extended-keys on
          set -as terminal-features 'xterm*:extkeys'
          set -g extended-keys-format csi-u

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

          # session: fzf switch (C-f) / create or attach (C-n)
          bind C-f display-popup -E -w 60% -h 40% "\
            tmux list-sessions -F '#{session_name}' \
            | ${pkgs-unstable.fzf}/bin/fzf --reverse --prompt='session> ' \
            | xargs -r tmux switch-client -t"
          bind C-n command-prompt -p "new session:" \
            "new-session -A -s '%%' -c '#{pane_current_path}'"

          # split current window horizontally
          bind - split-window -v -c '#{pane_current_path}'
          # split current window vertically
          bind | split-window -h -c '#{pane_current_path}'

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
          bind p split-window -h -c '#{pane_current_path}' pi  # vertical split, same cwd, run pi
          bind -r C-h previous-window # select previous window
          bind -r C-l next-window     # select next window
          bind Tab last-window        # move to last active window

          # --- catppuccin statusline (after plugins: HM mkAfter extraConfig) ---
          set -g status-right-length 100
          set -g status-left-length 100
          set -g status-left  "#{E:@catppuccin_status_session}"
          set -g status-right "#{E:@catppuccin_status_application}"

          # Command prompt (prefix + :) is drawn ON TOP of the status line, not
          # instead of it. Catppuccin defaults to centre-aligned messages with
          # no full-width cover, so window tabs on the left stay visible and
          # bury the text you type. Force a full-width opaque prompt.
          set -gF message-style "fg=#{@thm_teal},bg=#{@thm_mantle},align=left,width=100%,fill=#{@thm_mantle}"
          set -gF message-command-style "fg=#{@thm_teal},bg=#{@thm_mantle},align=left,width=100%,fill=#{@thm_mantle}"
        '';
      };
    };
  };
}
