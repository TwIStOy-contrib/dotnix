{pkgs, ...}: {
  programs.git = {
    # Route git http(s) traffic through the local mihomo mixed port.
    settings = {
      http.proxy = "http://127.0.0.1:7893";
      https.proxy = "http://127.0.0.1:7893";
    };
  };

  programs.ssh = {
    # Equivalent to the old `Host github.com / ProxyCommand` extraConfig block:
    # route github ssh through the local mihomo mixed port.
    matchBlocks = {
      "github.com".proxyCommand = "${pkgs.netcat}/bin/nc -X 5 -x 127.0.0.1:7893 %h %p";
      "poi.local" = {
        hostname = "192.168.50.226";
        user = "hawtian";
        forwardAgent = true;
        forwardX11 = true;
        extraOptions = {
          KeepAlive = "yes";
        };
      };
    };
  };
}
