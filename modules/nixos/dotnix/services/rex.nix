{
  config,
  inputs,
  lib,
  dotnix-constants,
  dotnix-utils,
  ...
}: let
  inherit (dotnix-constants) user;
  cfg = config.dotnix.services.rex;
  # Absolute path for Rex-launched commands: the rex server's PATH carries
  # only the systemd defaults, so anything from the HM profile (fish, pi,
  # git, ...) must be reached through a login shell started by path.
  hmProfileBin = "/etc/profiles/per-user/${user.name}/bin";
  hmConfigDir = "/home/${user.name}/.config";
in {
  imports = [inputs.rex.nixosModules.default];

  options.dotnix.services.rex = {
    enable = lib.mkEnableOption "Rex server, superlogical's programmable terminal";
  };

  config = lib.mkIf cfg.enable {
    services.rex = {
      enable = true;
      # Run the server (and every session it starts) as the real user
      # account instead of the synthetic "rex" system user, so Mac-app
      # sessions get hawtian's HOME and environment. /var/lib/rex is a
      # systemd StateDirectory and is chowned automatically on switch.
      user = user.name;
      group = "users";
      # Owner-only socket: the local user is the owner now, so no group
      # access is needed (the serve socket is always 0600 anyway).
      socketMode = "0600";
      # Remote access for the macOS Rex app through Tailscale Serve: HTTPS
      # with identity forwarding, no firewall ports. Requires the host to be
      # enrolled on a tailnet with HTTPS certificates available.
      tailscaleServe.enable = true;
      # taihou is a tagged node (tag:homeserver); tagged nodes have no owner
      # identity, so owner-only admission would admit nobody. Admit
      # identified tailnet users instead.
      tailnetAllowIdentified = true;
      # Tailscale Serve cannot forward the identity of TAGGED callers, so the
      # tagged Macs connect through this direct tailnet listener (identified
      # by tailscaled itself, no TLS/SNI needed; WireGuard encrypts the
      # transport). Vendor pattern from the extraListen docs. Clients use
      # "taihou.li-rankine.ts.net:7298" — never the bare tailnet IP over the
      # Serve port (no SNI → TLS handshake fails).
      extraListen = ["tailnet://:7298"];
    };

    # Point local rex commands at the system server by default; without this
    # the CLI auto-spawns a personal server with its own sessions. (The
    # `rex server status/stop` subcommands always manage the personal
    # server and ignore this variable.)
    environment.sessionVariables.REX_SERVER = "unix:///run/rex/server.sock";

    # User-side setup from the same flake: installs the rex command for the
    # user, writes the xterm-rex terminfo entry to ~/.terminfo, and adds the
    # ssh guard that stops TERM=xterm-rex from leaking to hosts without it
    # (works through programs.ssh, enabled by dotnix.nixos-shared).
    home-manager = dotnix-utils.hm.hmConfig {
      imports = [inputs.rex.homeManagerModules.default];
      programs.rex.enable = true;
      # init.lua is read by the Rex server only; it pushes the merged keymap
      # and actions to connected clients (palette + any future rex.bind on
      # the Mac app). Shared with the macOS local server via
      # modules/shared/dotnix/rex/init.lua. Apply changes with
      # `rex config reload` on this host — it is refused over remote
      # connections.
      programs.rex.config =
        lib.replaceStrings
        ["@hmProfileBin@" "@rexBin@" "@hmConfigDir@" "@rexServer@"]
        [hmProfileBin "${hmProfileBin}/rex" hmConfigDir "unix:///run/rex/server.sock"]
        (builtins.readFile ../../../shared/dotnix/rex/init.lua);

      # Remote actions require display metadata supplied by the target Mac.
      # The Mac's rex-font-fit command can also run this script locally
      # against this server, without installing a display helper on Linux.
      xdg.configFile."rex/font-fit.lua".text =
        builtins.readFile ../../../shared/dotnix/rex/font-fit.lua;
      # HM fish rewrites PATH on startup, which can push the server's own rex
      # binary behind the system one inside Rex terminals (Rex docs, "PATH").
      programs.fish.interactiveShellInit = ''
        if set -q REX_BIN_DIR
            fish_add_path --path --prepend --move $REX_BIN_DIR
        end
      '';
    };

    # Same guard for interactive bash/zsh shells.
    environment.interactiveShellInit = ''
      if [ -n "$REX_BIN_DIR" ]; then
        export PATH="$REX_BIN_DIR:$PATH"
      fi
    '';
  };
}
