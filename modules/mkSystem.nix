{
  self,
  inputs,
  nix-darwin,
  nixpkgs,
  home-manager,
  agenix,
  dotnixConstants,
  buildDotnixUtils,
  buildDotnixPkgs,
  vscode-server,
  ...
}: let
  inherit (nixpkgs.lib.strings) hasSuffix;

  sharedModule = import ./shared;
  nixosModule = import ./nixos;
  darwinModule = import ./darwin;

  darwinModules = [
    home-manager.darwinModules.home-manager
    agenix.darwinModules.default
    darwinModule
  ];
  nixosModules = [
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    vscode-server.nixosModules.default
    nixosModule
  ];
  buildPlatformModules = system:
    [sharedModule]
    ++ (
      if (hasSuffix "darwin" system)
      then darwinModules
      else nixosModules
    );
in
  {
    system,
    env ? "default",
  }: let
    pkgs-unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (_: prev: {
          neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (_: {
            doCheck = false;
            doInstallCheck = false;
          });
        })
      ];
    };
    # Use neovim packages from the overlay's own pinned nixpkgs
    # to avoid compatibility issues with nixpkgs-unstable
    neovim-pkgs =
      builtins.mapAttrs
      (_: pkg:
        if pkg ? overrideAttrs
        then
          pkg.overrideAttrs
          (_: {
            doCheck = false;
            doInstallCheck = false;
          })
        else pkg)
      inputs.neovim-nightly-overlay.packages.${system};
    isDarwin = hasSuffix "darwin" system;
    mkSystemImpl =
      if isDarwin
      then nix-darwin.lib.darwinSystem
      else nixpkgs.lib.nixosSystem;
    platModules = buildPlatformModules system;
    # re-export selected environment constants to modules.
    dotnix-constants = dotnixConstants.varsFor env;
    # llm-agents
    llm-agents = inputs.llm-agents .packages.${system};
    dotnix-utils = buildDotnixUtils {
      inherit inputs dotnix-constants;
    };
    dotnix-pkgs = buildDotnixPkgs {
      inherit pkgs-unstable llm-agents;
    };
  in
    {
      modules,
      home-modules,
    }: let
      # inject the specialArgs into all modules and home-manager modules
      specialArgs = {
        inherit dotnix-constants dotnix-utils dotnix-pkgs;
        # unstable channel
        inherit pkgs-unstable;
        # neovim packages from nightly overlay
        inherit neovim-pkgs;
        # llm-agents
        inherit llm-agents;
        # my nur channel
        inherit (inputs) nur-hawtian secrets-hawtian;
        # self!
        inherit self;
        # inject `inputs`
        inherit inputs;
        # inject darwin check
        inherit isDarwin;
      };
    in
      mkSystemImpl {
        inherit system specialArgs;

        modules =
          platModules
          ++ modules
          ++ [
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = specialArgs;
                users."${dotnix-constants.user.name}" = {
                  imports =
                    [
                      ./home
                    ]
                    ++ home-modules;
                };
              };
            }
          ];
      }
