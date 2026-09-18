{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  dotnix-utils,
  dotvim-ne,
  ...
}: let
  cfg = config.dotnix.desktop.neovide;
  settingsFormat = pkgs.formats.toml {};
  genConfig = opts: settingsFormat.generate "config.toml" opts;
  neovideBin =
    if pkgs.stdenv.hostPlatform.isDarwin
    then
      # https://github.com/neovide/neovide/issues/915
      "/Applications/Neovide.app/Contents/MacOS/neovide"
    else "neovide";
in {
  options.dotnix.desktop.neovide = {
    enable = lib.mkEnableOption "neovide";

    package = lib.mkOption {
      type = lib.types.enum ["stable" "unstable" "homebrew"];
      default = "stable";
      description = "neovide package from which channel";
    };

    # Remove this option after https://github.com/NixOS/nixpkgs/issues/290611 is fixed
    skipPackage = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Skip the package installation.
      '';
    };

    settings = {
      frame = lib.mkOption {
        type = lib.types.enum ["transparent" "full" "none" "buttonless"];
        default = "full";
        description = ''
          full: The default, all decorations.
          none: No decorations at all. NOTE: Window cannot be moved nor resized after this.
          (macOS only) transparent: Transparent decorations including a transparent bar.
          (macOS only) buttonless: All decorations, but without quit, minimize or fullscreen buttons.
        '';
      };

      maximized = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Maximize the window on startup, while still having decorations and the status bar of your OS visible.
        '';
      };

      idle = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          With idle on (default), neovide won't render new frames when nothing is happening.
          With idle off (e.g. with --no-idle flag), neovide will constantly render new frames, even when nothing changed. This takes more power and CPU time, but can possibly help with frame timing issues.

        '';
      };

      srgb = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Request sRGB support on the window. Neovide does not actually render with sRGB, but it's still enabled by default on Windows to work around neovim/neovim/issues/907. Other platforms should not need it, but if you encounter either startup crashes or wrong colors, you can try to swap the option. The command line parameter takes priority over the environment variable.

        '';
      };

      neovim-bin = lib.mkOption {
        type = lib.types.package;
        default = dotvim-ne;
        description = ''
          Package providing the neovim entry point. Resolved via `meta.mainProgram`.
        '';
      };
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        Extra settings to add to the config.toml file.
      '';
    };

    createRemoteHostWrappers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of remote hosts to create wrappers for.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = let
      # Adding "--wsl" to the neovide command line is a HACK to make neovide use local clipboard instead of remote.
      mkNeovideWrapper = host:
        pkgs.writeShellScriptBin "neovide-${host}" ''
          #!/bin/bash
          ${neovideBin} --neovim-bin "$XDG_CONFIG_HOME/neovide/remote-hosts/${host}" $@ --wsl
        '';

      # Remote hosts are reached through a persistent nvim --listen plus an et
      # tunnel, instead of pretending ssh is a neovim binary. et reconnects the
      # tunnel on its own, so a dropped link doesn't kill the remote server or
      # force neovide to spawn a new nvim.
      #
      # "--wsl" is a HACK that makes neovide use the local clipboard.
      mkNeovideRelayWrapper = host:
        pkgs.writeShellScriptBin "neovide-${host}-relay" ''
          set -euo pipefail

          host=${lib.escapeShellArg host}
          # Stable per-host port so a later launch reattaches to the same nvim
          # instead of starting another one. TCP rather than a unix socket:
          # forwarding a socket path needs et 7, and the NixOS hosts still
          # run 6.2. Both ends stay on 127.0.0.1.
          remote_port=$(printf '%s' "$host" | cksum | awk '{print 40000 + ($1 % 20000)}')

          state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/neovide-remote/$host"
          mkdir -p "$state_dir"

          port_file="$state_dir/port"
          pid_file="$state_dir/et.pid"
          log_file="$state_dir/et.log"

          py=${pkgs.python3}/bin/python3

          pick_port() {
            "$py" -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
          }

          et_alive() {
            [[ -f "$pid_file" ]] || return 1
            kill -0 "$(cat "$pid_file")" 2>/dev/null
          }

          port_open() {
            "$py" -c 'import socket, sys; s = socket.socket(); s.settimeout(0.2); raise SystemExit(s.connect_ex(("127.0.0.1", int(sys.argv[1]))))' "$1"
          }

          # Login fish can print a greeting, so the port comes back on a
          # marked line. nohup + disown so ssh exiting doesn't take nvim down.
          marked=$(ssh "$host" fish -l -c '
            set port $argv[1]
            function listening
              bash -c "echo >/dev/tcp/127.0.0.1/$argv[1]" >/dev/null 2>&1
            end
            if not listening $port
              nohup ne --listen 127.0.0.1:$port --headless >/tmp/neovide-server.log 2>&1 &
              disown
              set ok 0
              for i in (seq 1 50)
                if listening $port
                  set ok 1
                  break
                end
                sleep 0.1
              end
              if test $ok -eq 0
                echo "remote nvim did not start listening on 127.0.0.1:$port" >&2
                exit 1
              end
            end
            echo NEOVIDE_PORT=$port
          ' "$remote_port")
          remote_port=$(printf '%s\n' "$marked" | sed -n 's/^NEOVIDE_PORT=//p' | tail -1)
          if [[ -z "$remote_port" ]]; then
            echo "neovide-${host}-relay: remote nvim server did not report a port" >&2
            printf '%s\n' "$marked" >&2
            exit 1
          fi

          if et_alive && [[ -f "$port_file" ]] && port_open "$(cat "$port_file")"; then
            local_port="$(cat "$port_file")"
          else
            rm -f "$pid_file"
            local_port="$(pick_port)"
            echo "$local_port" > "$port_file"
            # -N: no remote shell, just the forward. et itself reconnects it
            # across network drops. Needs a 7.x client; the server can be older.
            et "$host" -N -t "$local_port:$remote_port" >> "$log_file" 2>&1 &
            echo $! > "$pid_file"
          fi

          for _ in $(seq 1 50); do
            port_open "$local_port" && break
            sleep 0.1
          done

          if ! port_open "$local_port"; then
            echo "neovide-${host}-relay: et forward 127.0.0.1:$local_port -> $host:$remote_port did not come up" >&2
            echo "see $log_file" >&2
            exit 1
          fi

          # Neovide follows the listen address from :restart. That address is
          # on the remote host, so a local relay holds the port Neovide dials
          # and opens a new et forward when the address changes.
          relay_port="$(pick_port)"
          "$py" ${./neovide-relay.py} \
            --listen "127.0.0.1:$relay_port" \
            --upstream "127.0.0.1:$local_port" \
            --remote-port "$remote_port" \
            --host "$host" &
          relay_pid=$!

          for _ in $(seq 1 50); do
            port_open "$relay_port" && break
            sleep 0.05
          done
          if ! port_open "$relay_port"; then
            kill "$relay_pid" 2>/dev/null || true
            echo "neovide-${host}-relay: local reconnect relay did not come up" >&2
            exit 1
          fi

          trap 'kill "$relay_pid" 2>/dev/null || true' EXIT
          exec ${neovideBin} --server "127.0.0.1:$relay_port" --wsl "$@"
        '';
    in
      (
        if cfg.package == "stable"
        then [pkgs.neovide]
        else if cfg.package == "unstable"
        then [pkgs-unstable.neovide]
        else []
      )
      ++ (lib.lists.forEach cfg.createRemoteHostWrappers mkNeovideWrapper)
      ++ (lib.lists.forEach cfg.createRemoteHostWrappers mkNeovideRelayWrapper)
      ++ (lib.lists.optional pkgs.stdenv.hostPlatform.isDarwin (
        pkgs.writeShellScriptBin "neovide" ''
          exec ${neovideBin} "$@"
        ''
      ));

    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile = let
        mkRemoteNvimBin = host: {
          "neovide/remote-hosts/${host}" = {
            source = pkgs.writeShellScript host ''
              #!/bin/bash
              ssh ${host} "fish -l -c \"ne $@\""
            '';
            force = true;
            executable = true;
          };
        };
      in
        lib.mkMerge (
          [
            {
              "neovide/config.toml" = {
                source = genConfig ({
                    inherit (cfg.settings) maximized frame srgb idle;
                    neovim-bin = lib.getExe cfg.settings.neovim-bin;
                  }
                  // cfg.extraSettings);
                force = true;
              };
            }
          ]
          ++ (lib.lists.forEach cfg.createRemoteHostWrappers mkRemoteNvimBin)
        );
    };
  };
}
