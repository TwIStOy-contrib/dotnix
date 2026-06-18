{
  pkgs-unstable,
  nur-hawtian,
  config,
  ...
}: {
  disabledModules = [
    "services/networking/frp.nix"
  ];

  imports = [
    "${nur-hawtian}/modules/services/networking/frp.nix"
  ];

  environment.etc = {
    "frp/frp-server-auth.toml" = {
      source = config.age.secrets."frp-server-auth.toml".path;
    };
    "frp/frp-proxies.toml" = {
      text = ''
        [[proxies]]
        localIP = "127.0.0.1"
        localPort = 22
        name = "poi-host-ssh"
        remotePort = 4002
        type = "tcp"

        [[proxies]]
        localIP = "127.0.0.1"
        localPort = 22
        name = "poi-ssh-p2p"
        secretKey = "hawtian"
        type = "xtcp"

        [[proxies]]
        localIP = "127.0.0.1"
        localPort = 2022
        name = "poi-et"
        remotePort = 9000
        type = "tcp"
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
