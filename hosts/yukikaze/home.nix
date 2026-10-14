_: {
  programs.ssh = {
    settings = {
      "poi.local" = {
        HostName = "192.168.50.226";
        User = "hawtian";
        ForwardAgent = true;
        ForwardX11 = true;
        KeepAlive = "yes";
      };
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
