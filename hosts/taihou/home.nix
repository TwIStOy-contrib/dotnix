{pkgs, ...}: {
  programs.git = {
    # Route git http(s) traffic through the local mihomo mixed port.
    settings = {
      http.proxy = "http://127.0.0.1:7893";
      https.proxy = "http://127.0.0.1:7893";
    };
  };

  programs.ssh = {
    # Route GitHub SSH through the local mihomo mixed port.
    settings = {
      "github.com".ProxyCommand = "${pkgs.netcat}/bin/nc -X 5 -x 127.0.0.1:7893 %h %p";
      "poi.local" = {
        HostName = "192.168.50.226";
        User = "hawtian";
        ForwardAgent = true;
        ForwardX11 = true;
        KeepAlive = "yes";
      };
    };
  };
}
