{
  config,
  lib,
  inputs,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.neovim;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  hm-dag = inputs.home-manager.lib.hm.dag;
in {
  options.dotnix.apps.neovim = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.neovim";
  };

  config = lib.mkIf cfg.enable {
    home-manager = lib.mkMerge [
      (dotnix-utils.hm.hmModule ./home.nix)
      (dotnix-utils.hm.hmConfig {
        home.activation.setup-dotvim = hm-dag.entryAfter ["linkGeneration"] ''
          if [ ! -d "${homeDir}/.dotvim" ]; then
            $DRY_RUN_CMD git clone git@github.com:TwIStOy/dotvim.git "${homeDir}/.dotvim"
          fi
        '';
      })
    ];
  };
}
