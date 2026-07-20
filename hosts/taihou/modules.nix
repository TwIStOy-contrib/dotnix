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
