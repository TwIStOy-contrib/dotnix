_: let
  # The standard two-window layout the old per-file smug YAML configs used:
  # an agent pane plus a selected editor window. `pi` and `ne` resolve from
  # the user profile PATH inside tmux panes.
  devSession = root: {
    inherit root;
    windows = [
      {
        name = "Agent";
        commands = ["pi"];
      }
      {
        name = "Editor";
        selected = true;
        commands = ["ne"];
      }
    ];
  };
in {
  dotnix = {
    apps.htw.sessions = {
      dotvim = devSession "~/.dotvim";
      hat = devSession "~/Projects/hat";
      hpm = devSession "~/Projects/hpm";
      htw = devSession "~/Projects/htw";
      pi-ext = devSession "~/pi-extensions";
      proxy-rules = devSession "~/Projects/proxy-rules";
      lite-gateway = {
        root = "~/Projects/lite-gateway";
        windows = [
          {
            name = "Agent";
            commands = ["pi"];
          }
          {
            name = "Editor";
            selected = true;
            commands = ["ne"];
          }
          {
            name = "Run";
            commands = ["just run-backend"];
            panes = [
              {
                type = "horizontal";
                commands = ["just run-frontend"];
              }
            ];
          }
        ];
      };
    };

    apps.htw.daemon = {
      # Central agent-sessions daemon: accept producers from the LAN and the
      # tailnet (loopback is always allowed). Port stays htw's default 7482.
      bind = "0.0.0.0";
      allow = [
        "192.168.50.0/24"
        "100.64.0.0/10"
      ];
    };

    nixos-shared-suit = {
      enable = true;
    };
    desktop.neovide.extraSettings.font.size = 22;
    apps.ollama = {
      enable = false;
    };
    # ssh agent socket manager for tmux (keeps SSH_AUTH_SOCK pointed at the
    # active tmux client across multiple simultaneous SSH/ET connections).
    apps.socklink.enable = true;
    services.github-runner = {
      enable = false;
    };
    services.moshi = {
      enable = true;
      # Route through the local mihomo mixed port (127.0.0.1:7893) instead
      # of the LAN proxy on poi.
      proxyUrl = "http://127.0.0.1:7893";
    };

    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:homeserver"
        "--ssh"
      ];
    };
    services.eternal-terminal = {
      enable = true;
    };
  };
}
