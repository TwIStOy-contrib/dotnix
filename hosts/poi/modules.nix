{...}: {
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
    # fish is the interactive shell everywhere (tmux panes, terminals);
    # make it the login shell too so ssh/ET/rex land directly in it.
    apps.fish.loginShell = true;
    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:homeserver"
        "--ssh"
        "--accept-dns=false"
      ];
    };
    services.eternal-terminal = {
      enable = true;
    };
    services.rex = {
      enable = true;
    };
  };
}
