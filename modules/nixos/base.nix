{pkgs, ...}: {
  programs.ssh = {
    startAgent = true;
  };

  programs.nix-ld.enable = true;

  environment.enableAllTerminfo = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    aria2

    # create a fhs environment by command `fhs`, so we can run non-nixos packages in nixos!
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
        pkgs.buildFHSEnv (base
          // {
            name = "fhs";
            targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config];
            profile = "export FHS=1";
            runScript = "bash";
            extraOutputsToInstall = ["dev"];
          })
    )
  ];
}
