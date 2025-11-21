_: {
  programs.ssh = {
    extraConfig = ''
      Host github.com
          HostName %h
          ProxyCommand nc -X 5 -x 192.168.50.217:6152 %h %p
    '';
    matchBlocks = {
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
