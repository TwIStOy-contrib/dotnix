{
  lib,
  stdenv,
  fetchurl,
}:
# moshi-hook is a closed-source binary distribution downloaded from the
# upstream CDN. The installer (https://getmoshi.app/install.sh) fetches
# `moshi-hook_<os>_<arch>.tar.gz` and ships only a prebuilt `moshi-hook`
# binary, so we treat it as a black box: download, extract, install.
#
# CDN layout:
#   https://cdn.getmoshi.app/hook/v<version>/moshi-hook_<os>_<arch>.tar.gz
#   https://cdn.getmoshi.app/hook/v<version>/checksums.txt   (official sha256 of each tarball)
#
# To bump the version: change `version`, pull the new hashes from the
# versioned checksums.txt, convert with `nix hash to-sri --type sha256 <hex>`,
# and update `hashes` below.
let
  version = "0.2.27";

  # Map nixpkgs platform -> (os, arch) used in the upstream asset name.
  # Mirrors the install.sh logic (uname -s -> Linux/Darwin, uname -m -> x86_64/arm64).
  os =
    if stdenv.hostPlatform.isDarwin
    then "Darwin"
    else "Linux";
  arch =
    if stdenv.hostPlatform.isAarch64
    then "arm64"
    else "x86_64";

  # sha256 (SRI) per asset, sourced from the official checksums.txt at
  # https://cdn.getmoshi.app/hook/v<version>/checksums.txt
  hashes = {
    "Linux-x86_64" = "sha256-mAN64DJP9F64+g2doYiFsveA3b4MziUmSrj+QLxD5+0=";
    "Linux-arm64" = "sha256-ZcaTdJau2wlnWkywqS3mRd9tXgpg//IJgVzNYsaZO4U=";
    "Darwin-x86_64" = "sha256-06PsJteEcmTk4wbbRUFJ/2geRUwhpO1Ti5tWJwugwN0=";
    "Darwin-arm64" = "sha256-VVqR/33nZjHw2Ky4GzUhKz7nGSBoRkLBDR+8RGO5QrA=";
  };
  key = "${os}-${arch}";
  hash =
    hashes.${key}
      or (throw "moshi-hook: no hash registered for ${stdenv.hostPlatform.system} (${key})");

  asset = "moshi-hook_${os}_${arch}.tar.gz";
in
  stdenv.mkDerivation {
    pname = "moshi-hook";
    inherit version;

    src = fetchurl {
      url = "https://cdn.getmoshi.app/hook/v${version}/${asset}";
      inherit hash;
    };

    dontConfigure = true;
    dontBuild = true;

    # tarball ships a prebuilt static binary + docs; no patchelf needed.
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/doc/moshi-hook
      tar -xzf $src

      install -m755 moshi-hook $out/bin/moshi-hook
      # upstream installer also exposes a `moshi` convenience alias.
      ln -s moshi-hook $out/bin/moshi

      cp README.md $out/share/doc/moshi-hook/ 2>/dev/null || true
      cp -r docs $out/share/doc/moshi-hook/ 2>/dev/null || true

      runHook postInstall
    '';

    meta = with lib; {
      description = "Moshi agent hook (closed-source binary) for Easy Pair SSH/Mosh and agent pairing";
      homepage = "https://getmoshi.app/";
      # Not open source; redistributed only as a prebuilt binary.
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "moshi-hook";
      platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    };
  }
