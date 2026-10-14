{pkgs, ...}: {
  programs.ssh = {
    # Route GitHub SSH through the LAN proxy on poi.
    settings = {
      "github.com".ProxyCommand = "${pkgs.netcat}/bin/nc -X 5 -x 192.168.50.217:6153 %h %p";
      "taihou.local" = {
        HostName = "192.168.50.252";
        User = "hawtian";
        ForwardAgent = true;
        ForwardX11 = true;
        KeepAlive = "yes";
      };
    };
  };
}
