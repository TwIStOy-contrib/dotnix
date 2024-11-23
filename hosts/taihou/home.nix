_: {
  programs.ssh = {
    extraConfig = ''
      Host github.com
          HostName %h
          ProxyCommand nc -X 5 -x 192.168.50.217:8889 %h %p
    '';
    matchBlocks = {
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
