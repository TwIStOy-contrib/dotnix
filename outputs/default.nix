{self, ...} @ inputs: let
  inherit (inputs) flake-utils nixpkgs;

  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  dotnixConstants = import ../lib/constants;

  buildDotnixUtils = import ../lib/utils;
  buildDotnixPkgs = import ../lib/pkgs;
  mkSystem = import ../modules/mkSystem.nix (
    {
      inherit self inputs dotnixConstants buildDotnixUtils buildDotnixPkgs;
    }
    // inputs
  );

  formatter = import ./formatter.nix (inputs // {inherit supportedSystems;});

  hostsConfiguration = import ../hosts {
    inherit (inputs) flake-utils nixpkgs deploy-rs;
    inherit mkSystem;
    vars = dotnixConstants;
  };

  templates = {
    templates.devenv = {
      path = ../templates/devenv;
      description = "devenv templates";
    };
  };

  recursiveMergeAttrs = attrs: builtins.foldl' (acc: ext: nixpkgs.lib.attrsets.recursiveUpdate acc ext) {} attrs;
  preCommitChecks = flake-utils.lib.eachSystem supportedSystems (system: {
    checks = {
      pre-commit-check =
        inputs.pre-commit-hooks.lib.${system}.run
        {
          src = ../.;
          hooks = {
            actionlint.enable = true;

            statix = {
              enable = true;
            };

            alejandra = {
              enable = true;
              excludes = [
                "hardware-configuration.*.nix"
                ".*vim-template.*"
              ];
            };
          };

          settings = {
            # Work around for `statix`,
            # issue: https://github.com/cachix/pre-commit-hooks.nix/issues/288
            statix.ignore = [
              "hardware-configuration.nix"
              ".vim-template:*.nix"
              ".vim-template:default.nix"
            ];
          };
        };
    };
  });
  deployChecks = {
    checks = nixpkgs.lib.genAttrs supportedSystems (system: inputs.deploy-rs.lib.${system}.deployChecks self.deploy);
  };
  checks = recursiveMergeAttrs [
    preCommitChecks
    deployChecks
  ];
in
  nixpkgs.lib.attrsets.mergeAttrsList [
    hostsConfiguration
    formatter
    templates
    checks
  ]
