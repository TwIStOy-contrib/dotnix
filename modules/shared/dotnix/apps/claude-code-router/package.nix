{
  lib,
  stdenv,
  fetchzip,
  nodejs,
}: let
  version = "1.0.73";
  hash = "sha256-NeCrCC2Am48ctaEpQs+bQJDPrY/gtpV39HmzGElh0ak=";
in
  stdenv.mkDerivation {
    pname = "claude-code-router";
    inherit version;

    src = fetchzip {
      url = "https://registry.npmjs.org/@musistudio/claude-code-router/-/claude-code-router-${version}.tgz";
      inherit hash;
    };

    nativeBuildInputs = [nodejs];

    installPhase = ''
      runHook preInstall

      # The npm package already contains built files
      mkdir -p $out/bin
      mkdir -p $out/dist
      cp $src/dist/cli.js $out/bin/ccr
      chmod +x $out/bin/ccr

      # Replace the shebang with the correct node path
      substituteInPlace $out/bin/ccr --replace-quiet "#!/usr/bin/env node" "#!${nodejs}/bin/node"

      # Install the WASM file in the same directory as the CLI
      cp $src/dist/tiktoken_bg.wasm $out/bin/
      cp $src/dist/* $out/dist/

      runHook postInstall
    '';

    meta = with lib; {
      description = "Use Claude Code without an Anthropics account and route it to another LLM provider";
      homepage = "https://github.com/musistudio/claude-code-router";
      changelog = "https://github.com/musistudio/claude-code-router/releases";
      license = licenses.mit;
      sourceProvenance = with lib.sourceTypes; [binaryBytecode];
      maintainers = with maintainers; [];
      mainProgram = "ccr";
      platforms = platforms.all;
    };
  }
