{
  pkgs,
  pkgs-unstable,
  ...
}: {
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
    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:homeserver"
        "--ssh"
        "--accept-dns=false"
      ];
    };
    services.fava = {
      enable = true;
      port = 5000;
      home = "/var/lib/fava";
      mainFile = "main.bean";
      accountBookRepo = "git@github.com:TwIStOy-contrib/account-book.git";
    };
    services.moshi = {
      enable = true;
    };
    services.eternal-terminal = {
      enable = true;
    };
  };

  services.github-runners = {
    general-private-contrib = {
      enable = false;
      name = "poi-private-contrib";
      tokenFile = "/run/agenix/github-actions-runner-token";
      url = "https://github.com/TwIStOy-contrib";
      extraLabels = [
        "nixos"
      ];
      replace = true;
      extraPackages = with pkgs; [
        docker
      ];
    };
    account-book = {
      enable = false;
      name = "poi-account-book";
      tokenFile = "/run/agenix/github-actions-runner-token";
      url = "https://github.com/TwIStOy-contrib";
      extraLabels = [
        "nixos"
        "beancount"
      ];
      runnerGroup = "beancount";
      replace = true;
      extraPackages = with pkgs-unstable; [
        beancount
      ];
    };
  };
}
