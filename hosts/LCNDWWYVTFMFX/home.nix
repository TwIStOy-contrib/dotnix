_: {
  programs.ssh = {
    matchBlocks = {
      "dev.work.local" = {
        hostname = "10.114.192.14";
        user = "wanghaot";
        forwardAgent = true;
        forwardX11 = true;
        extraOptions = {
          KeepAlive = "yes";
        };
      };
      "dev.work.local.tmux" = {
        hostname = "10.114.192.14";
        user = "wanghaot";
        forwardAgent = true;
        forwardX11 = true;
        extraOptions = {
          KeepAlive = "yes";
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s dev";
        };
      };
    };
  };
}
