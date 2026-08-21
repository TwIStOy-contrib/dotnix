{
  pkgs-unstable,
  config,
  ...
}: {
  environment.etc = {
    "frp/frp-server-auth.toml" = {
      source = config.age.secrets."frp-server-auth.toml".path;
    };
    "frp/frp-proxies.toml" = {
      text = ''
        [[proxies]]
        localIP = "127.0.0.1"
        localPort = 22
        name = "taihou-host-ssh"
        remotePort = 4003
        type = "tcp"

        [[proxies]]
        localIP = "127.0.0.1"
        localPort = 22
        name = "taihou-ssh-p2p"
        secretKey = "hawtian"
        type = "xtcp"
      '';
    };
  };

  services.frp = {
    enable = true;
    package = pkgs-unstable.frp;
    role = "client";
    configFile = "/etc/frp/frp-server-auth.toml";
  };
}
