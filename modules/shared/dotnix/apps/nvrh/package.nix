{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
# nvrh (Neovim Remote Helper) — work with a remote Neovim instance like
# VSCode Remote: start nvim on a server, tunnel the socket over SSH, and
# drive it from a local editor.
#
# Upstream has no Nix packaging; releases are plain binaries built by
# script/build, which does `cp package.json src/` before `go build` because
# src/main.go `//go:embed package.json` reads name/version from it. We
# replicate that copy in postPatch.
let
  version = "0.9.1";
in
  buildGoModule {
    pname = "nvrh";
    inherit version;

    src = fetchFromGitHub {
      owner = "mikew";
      repo = "nvrh";
      rev = "refs/tags/v${version}";
      hash = "sha256-b5H8ACD9p46nmjK3YXrM3U9BLn1zQRLfnLIG+c8FOxk=";
    };

    vendorHash = "sha256-vdKE1RaMlZo/n3Mob9AGNX/V8RCkf5EoQsJ0Zn1S8Jc=";

    # Main package lives in src/ (module layout: src/main.go), so the
    # produced binary is named "src" — rename it to nvrh like upstream's
    # `go build -o dist/nvrh-... ./src/main.go` does.
    subPackages = ["src"];

    postInstall = ''
      mv $out/bin/src $out/bin/nvrh
    '';

    # src/main.go embeds package.json (name/version for the CLI). Upstream's
    # build script copies it into src/ right before building.
    postPatch = ''
      cp package.json src/
    '';

    ldflags = [
      "-s"
      "-w"
    ];

    # No Go tests ship with the repo (script/test only covers the lua plugin).
    doCheck = false;

    meta = {
      description = "Neovim Remote Helper — work with a remote Neovim instance like VSCode Remote";
      homepage = "https://github.com/mikew/nvrh";
      changelog = "https://github.com/mikew/nvrh/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "nvrh";
      platforms = lib.platforms.unix;
    };
  }
