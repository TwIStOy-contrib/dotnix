{
  lib,
  pkgs,
}: {
  htwExecutable,
  realPiExecutable,
}:
pkgs.writeShellScriptBin "pi" ''
  agentDirectory="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
  configHome="''${XDG_CONFIG_HOME:-$HOME/.config}"
  staticSettings="$configHome/htw/pi-config"

  ${lib.escapeShellArg htwExecutable} pi-config sync \
    --agent-dir "$agentDirectory" \
    --layer-set "$staticSettings" \
    --phase preflight || exit $?

  postflight() {
    piStatus=$?
    trap - EXIT
    ${lib.escapeShellArg htwExecutable} pi-config sync \
      --agent-dir "$agentDirectory" \
      --layer-set "$staticSettings" \
      --phase postflight || true
    exit "$piStatus"
  }
  trap postflight EXIT

  ${lib.escapeShellArg realPiExecutable} "$@"
''
