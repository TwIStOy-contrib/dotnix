_: {
  programs.ssh = {
    settings = {
      "dev.work.local" = {
        HostName = "10.114.192.14";
        User = "wanghaot";
        ForwardAgent = true;
        ForwardX11 = true;
        KeepAlive = "yes";
      };
      "dev.work.local.tmux" = {
        HostName = "10.114.192.14";
        User = "wanghaot";
        ForwardAgent = true;
        ForwardX11 = true;
        KeepAlive = "yes";
        RequestTTY = "yes";
        RemoteCommand = "tmux new -A -s dev";
      };
    };
  };
}
