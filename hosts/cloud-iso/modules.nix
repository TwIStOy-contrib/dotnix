{
  pkgs,
  dotnix-utils,
  ...
}: let
  inherit (dotnix-utils) enableModules;
in {
  dotnix = {
    services.tailscale = {
      enable = true;
      extraUpFlags = [
        "--advertise-tags=tag:homeserver"
        "--ssh"
      ];
    };
    apps = enableModules [
      "eza"
      "fish"
      "starship"
    ];
  };
  environment.systemPackages = with pkgs; [
    neovim
    fastfetch
    zip
    xz
    unzip
    wget
    gnugrep
    gnused
    jq
    gawk
    fswatch
    curl
    git
  ];
}
