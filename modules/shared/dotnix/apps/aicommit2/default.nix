{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.aicommit2;
  aicommit2Pkg =
    inputs.aicommit2.packages.${pkgs.system}.default.overrideAttrs
    (old: {
      pnpmDeps = pkgs.pnpm.fetchDeps {
        inherit (old) pname version src;
        fetcherVersion = 1;
        hash = "sha256-34djAIYi+joZ1BvVatMeB4cQ9r7+PighiHkIYSqRJxU=";
      };
    });
  zAiApiKeyPath = config.age.secrets."z-ai-api-key".path;
  aicommit2 = pkgs.writeShellScriptBin "aicommit2" ''
    export ZHIPU_API_KEY="$(cat ${zAiApiKeyPath})"
    export NODE_TLS_REJECT_UNAUTHORIZED=0
    exec ${aicommit2Pkg}/bin/aicommit2 "$@"
  '';
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
          key=$ZHIPU_API_KEY
          url=https://api.z.ai/api/coding/paas/v4
          model=glm-5.1
        '';
        force = true;
      };
    };
  };
}
