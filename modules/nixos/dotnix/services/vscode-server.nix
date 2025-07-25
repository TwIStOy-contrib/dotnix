{
  config,
  lib,
  ...
}: let
  cfg = config.dotnix.services.vscode-server;
in {
  options.dotnix.services.vscode-server = {
    enable = lib.mkEnableOption "Enable module dotnix.services.vscode-server";
  };

  config = lib.mkIf cfg.enable {
    services.vscode-server.enable = true;
    services.vscode-server.installPath = "$HOME/.vscode-server-insiders";
  };
}
