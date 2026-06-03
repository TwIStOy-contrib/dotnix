{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  dotnix-pkgs,
  ...
}: let
  cfg = config.dotnix.apps.aicommit2;
  aicommit2Pkg = inputs.aicommit2.packages.${pkgs.system}.default;
  aicommit2 = dotnix-pkgs.mkWrappedProgram {
    name = "aicommit2";
    package = aicommit2Pkg;
    env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
    shellEnv = dotnix-pkgs.llmApiKeys;
  };
in {
  options.dotnix.apps.aicommit2 = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.aicommit2";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      aicommit2
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile."aicommit2/config.ini" = {
        text = ''
          generate=1
          locale=en
          type=conventional
          diffCompression=compact

          [ZAI_CODING_PLAN]
          compatible=true
          key=$ZAI_API_KEY
          url=https://api.z.ai/api/coding/paas/v4
          model=glm-5.1
        '';
        force = true;
      };
    };
  };
}
