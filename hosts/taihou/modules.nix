_: {
  dotnix = {
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
