{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "0.5.3";

  # The npm package is a thin Node wrapper; each @openviking/cli-<platform>
  # tarball carries one statically linked `bin/ov`, so no Node runtime is
  # needed at all.
  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-6WCBn18Fak2T98WHBpNxATIBd7k4m4MMwnrepYdUjmM=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-8JEXuYeldDK2/a0uqzi0bfGCMFAcmjenCuxjEDUy7MI=";
    };
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-azNXNPALSosq2cnSyYH266o0MqcY/7CAmROE8CdHnug=";
    };
    x86_64-darwin = {
      platform = "darwin-x64";
      hash = "sha256-IuCdqocn+uDM7HpV09jXEUDjeW+OOsb8hUlPGnFNBDo=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source =
    sources.${system}
    or (throw "openviking-cli: no npm platform package for ${system}");
in
  stdenvNoCC.mkDerivation {
    pname = "openviking-cli";
    inherit version;

    src = fetchurl {
      url = "https://registry.npmjs.org/@openviking/cli-${source.platform}/-/cli-${source.platform}-${version}.tgz";
      inherit (source) hash;
    };

    sourceRoot = "package";
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/ov "$out/bin/ov"
      runHook postInstall
    '';

    meta = {
      description = "OpenViking CLI — agent-native context database";
      homepage = "https://github.com/volcengine/OpenViking";
      license = lib.licenses.asl20;
      mainProgram = "ov";
      platforms = builtins.attrNames sources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
