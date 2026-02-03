{
  self,
  inputs,
  nix-darwin,
  nixpkgs,
  home-manager,
  agenix,
  vars,
  buildDotnixUtils,
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
    };
    # Use neovim packages from the overlay's own pinned nixpkgs
    # to avoid compatibility issues with nixpkgs-unstable
    neovim-pkgs = inputs.neovim-nightly-overlay.packages.${system};
    isDarwin = hasSuffix "darwin" system;
    mkSystemImpl =
      if isDarwin
      then nix-darwin.lib.darwinSystem
      else nixpkgs.lib.nixosSystem;
    platModules = buildPlatformModules system;
    # re-export vars to dotnix-constants
    dotnix-constants = vars.varsFor env;
    dotnix-utils = buildDotnixUtils {
      inherit inputs dotnix-constants;
    };
    # llm-agents
    llm-agents = inputs.llm-agents .packages.${system};
  in
    {
      modules,
      home-modules,
    }: let
      # inject the specialArgs into all modules and home-manager modules
      specialArgs = {
        inherit dotnix-constants dotnix-utils;
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
