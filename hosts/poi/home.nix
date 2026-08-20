{pkgs, ...}: {
  programs.ssh = {
    # Equivalent to the old `Host github.com / ProxyCommand` extraConfig block:
    # route github ssh through the LAN proxy on poi.
    matchBlocks = {
      "github.com".proxyCommand = "${pkgs.netcat}/bin/nc -X 5 -x 192.168.50.217:6153 %h %p";
      "taihou.local" = {
        hostname = "192.168.50.252";
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
