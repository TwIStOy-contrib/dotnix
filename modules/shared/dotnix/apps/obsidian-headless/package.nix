{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  python3,
}: let
  version = "0.0.14";
in
  buildNpmPackage {
    pname = "obsidian-headless";
    inherit version;

    src = fetchurl {
      url = "https://registry.npmjs.org/obsidian-headless/-/obsidian-headless-${version}.tgz";
      hash = "sha256-73UpjtOjVtyypN6Yxu/hCyrGSwBVYAcRi2rHBTXnMVY=";
    };

    # The official headless client for Obsidian Sync/Publish requires
    # Node.js >= 22 (declared in its `engines` field).
    nodejs = nodejs_22;

    # The published npm tarball ships no package-lock.json (only cli.js,
    # btime/, package.json, README.md). buildNpmPackage / fetchNpmDeps
    # require a lock to resolve dependencies deterministically, so inject
    # a vendored one generated from the upstream package.json.
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';

    npmDepsHash = "sha256-ta0JnpEumLN92G0mGihsOrUNBfpbBlV3mEAFBCEcfKI=";

    # better-sqlite3 is a native Node addon (node-gyp, not N-API, so it is
    # ABI-bound to the Node major it was built against). Its install script
    # first tries to download a prebuilt binary (prebuild-install); in the
    # Nix build sandbox there is no network, so force compilation from
    # source. better-sqlite3 bundles its own SQLite amalgamation, so no
    # system sqlite headers are needed — just python3 + the C++ toolchain
    # (the latter is provided by stdenv.cc by default).
    nativeBuildInputs = [
      python3
    ];

    preConfigure = ''
      export npm_config_build_from_source=true
    '';

    # The upstream package ships a prebuilt cli.js; there is no npm build
    # step to run, only the dependency install + native rebuild.
    dontNpmBuild = true;

    meta = with lib; {
      description = "Headless client for Obsidian Sync and Publish (the `ob` CLI)";
      homepage = "https://github.com/obsidianmd/obsidian-headless";
      # Upstream license is UNLICENSED; keep it unfree so a packaged
      # closure is never pushed to a public binary cache.
      license = licenses.unfree;
      mainProgram = "ob";
      platforms = platforms.darwin ++ platforms.linux;
    };
  }
