{
  description = "Dotnix: hawtian's nix configuration for both macos and linux";

  outputs = inputs: import ./outputs inputs;

  inputs = {
    # Official NixOS package source, using nixos's stable branch by default
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";

    flake-utils.url = "github:numtide/flake-utils";

    # for macos
    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        home-manager.follows = "home-manager";
      };
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    # rime-ls only: the nixpkgs rime-ls does not support aarch64-darwin
    nur-hawtian = {
      url = "github:TwIStOy/nur-packages";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    # Rex (superlogical's programmable terminal). The channel URL redirects to
    # an immutable per-release URL which flake.lock records, so locked
    # evaluations stay stable; `nix flake update rex` moves to the newest
    # snapshot. Downloads need the netrc secret at /etc/nix/netrc.
    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz";
      # Rex only needs stdenvNoCC/fetchurl/patchelf; reuse our unstable pin
      # instead of its own channels.nixos.org tarball download.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    secrets-hawtian = {
      url = "git+ssh://git@github.com/TwIStOy/nix-secret.git?shallow=1";
      flake = false;
    };

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # devenv, construct a development environment easily
    devenv.url = "github:cachix/devenv";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      # Don't follow nixpkgs-unstable to avoid compatibility issues
      # The overlay needs its own pinned nixpkgs version
    };

    # fix vscode server on nixos
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # use more vscode extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    deploy-rs.url = "github:serokell/deploy-rs";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotvim.url = "github:TwIStOy/dotvim";

    herdr.url = "github:ogulcancelik/herdr/v0.9.5";

    hat = {
      url = "git+ssh://git@github.com/TwIStOy/hat.git?shallow=1";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    htw = {
      url = "git+ssh://git@github.com/TwIStOy/htw.git?shallow=1";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
      };
    };

    hunk = {
      url = "github:modem-dev/hunk";
      # Hunk's package.nix sets dontFixup = true, so its bun-compiled binary
      # keeps the interpreter of the glibc it was built against. If that
      # differs from the host runtime glibc (e.g. unstable 2.42 vs stable
      # 2.40), the loader and libc mismatch and the binary segfaults.
      # Follow the same stable nixpkgs the system uses so they match.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
