{
  config,
  pkgs,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.utils.rime-scheme;

  rime-scheme = pkgs.fetchFromGitHub {
    owner = "Mintimate";
    repo = "oh-my-rime";
    rev = "1d93351a15f8b9dd66847ee887374c962bea4764";
    hash = "sha256-hDWJBBZQsROD5qp8XNqChgJhLODLAjg819/Y5q3dlIc=";
  };
in {
  options.dotnix.utils.rime-scheme = {
    enable = lib.mkEnableOption "Rime Scheme";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      xdg.dataFile.shared-rime-scheme = {
        source = rime-scheme;
        recursive = true;
      };
    };
  };
}
