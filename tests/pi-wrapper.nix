{
  pkgs,
  htw,
  lib ? pkgs.lib,
}: let
  mkPiWrapper = import ../lib/pkgs/pi-wrapper.nix {inherit lib pkgs;};
  fakeHtw = pkgs.writeShellScriptBin "htw" ''
    test "$#" -eq 8
    test "$1" = "pi-config"
    test "$2" = "sync"
    test "$3" = "--agent-dir"
    test "$4" = "$PI_WRAPPER_TEST_AGENT_DIR"
    test "$5" = "--layer-set"
    test "$6" = "$PI_WRAPPER_TEST_STATIC_SETTINGS"
    test "$7" = "--phase"
    case "$8" in
      preflight | postflight) ;;
      *) exit 2 ;;
    esac
    printf '%s\n' "$8" >>"$PI_WRAPPER_TEST_PHASES"

    if [ "$8" = preflight ] && [ -n "''${PI_WRAPPER_TEST_FAIL_PREFLIGHT:-}" ]; then
      exit "$PI_WRAPPER_TEST_FAIL_PREFLIGHT"
    fi
    if [ "$8" = postflight ] && [ -n "''${PI_WRAPPER_TEST_FAIL_POSTFLIGHT:-}" ]; then
      exit "$PI_WRAPPER_TEST_FAIL_POSTFLIGHT"
    fi
  '';
  fakeRealPi = pkgs.writeShellScriptBin "pi-real" ''
    printf 'launched\n' >>"$PI_WRAPPER_TEST_LAUNCHES"
    printf '%s\n' "$@" >"$PI_WRAPPER_TEST_ARGUMENTS"

    case "''${PI_WRAPPER_TEST_REAL_PI_BEHAVIOR:-success}" in
      success) ;;
      exit)
        exit "$PI_WRAPPER_TEST_REAL_PI_STATUS"
        ;;
      sigint)
        trap - INT
        kill -INT "$$"
        ;;
      sigterm)
        trap - TERM
        kill -TERM "$$"
        ;;
      *) exit 2 ;;
    esac
  '';
  wrapper = mkPiWrapper {
    htwExecutable = "${fakeHtw}/bin/htw";
    realPiExecutable = "${fakeRealPi}/bin/pi-real";
  };
  settingsMutatingPi = pkgs.writeShellScriptBin "pi-real" ''
    if [ -n "''${PI_WRAPPER_TEST_MALFORM_LIVE:-}" ]; then
      printf '%s' '{"malformed":' >"$PI_CODING_AGENT_DIR/settings.json"
      exit 0
    fi

    temporarySettings="$PI_CODING_AGENT_DIR/settings.json.next"
    ${pkgs.jq}/bin/jq \
      '.piChange = "from Pi" | .telemetry = true' \
      "$PI_CODING_AGENT_DIR/settings.json" >"$temporarySettings"
    mv "$temporarySettings" "$PI_CODING_AGENT_DIR/settings.json"
  '';
  integratedWrapper = mkPiWrapper {
    htwExecutable = lib.getExe htw;
    realPiExecutable = "${settingsMutatingPi}/bin/pi-real";
  };
in
  pkgs.runCommandLocal "pi-wrapper-lifecycle-test" {} ''
    export HOME="$TMPDIR/home with spaces"
    export XDG_CONFIG_HOME="$HOME/custom config"
    export PI_CODING_AGENT_DIR="$HOME/custom agent"
    export PI_WRAPPER_TEST_AGENT_DIR="$PI_CODING_AGENT_DIR"
    export PI_WRAPPER_TEST_STATIC_SETTINGS="$XDG_CONFIG_HOME/htw/pi-config"
    export PI_WRAPPER_TEST_PHASES="$TMPDIR/phases"
    export PI_WRAPPER_TEST_ARGUMENTS="$TMPDIR/arguments"
    export PI_WRAPPER_TEST_LAUNCHES="$TMPDIR/launches"

    mkdir -p "$PI_CODING_AGENT_DIR" "$PI_WRAPPER_TEST_STATIC_SETTINGS"

    runWrapper() {
      set +e
      ${wrapper}/bin/pi "$@"
      wrapperStatus=$?
      set -e
    }

    runWrapper \
      plain \
      "two words" \
      "contains'single-quote" \
      'contains"double-quote' \
      '$dollar;semicolon' \
      '$(must-not-execute)'
    test "$wrapperStatus" -eq 0

    diff -u <(printf '%s\n' \
      plain \
      "two words" \
      "contains'single-quote" \
      'contains"double-quote' \
      '$dollar;semicolon' \
      '$(must-not-execute)') \
      "$PI_WRAPPER_TEST_ARGUMENTS"
    diff -u <(printf '%s\n' preflight postflight) "$PI_WRAPPER_TEST_PHASES"
    test "$(wc -l <"$PI_WRAPPER_TEST_LAUNCHES")" -eq 1

    export HOME="$TMPDIR/default home"
    unset XDG_CONFIG_HOME PI_CODING_AGENT_DIR
    export PI_WRAPPER_TEST_AGENT_DIR="$HOME/.pi/agent"
    export PI_WRAPPER_TEST_STATIC_SETTINGS="$HOME/.config/htw/pi-config"
    : >"$PI_WRAPPER_TEST_PHASES"
    : >"$PI_WRAPPER_TEST_LAUNCHES"
    mkdir -p "$PI_WRAPPER_TEST_AGENT_DIR" "$PI_WRAPPER_TEST_STATIC_SETTINGS"
    runWrapper default-paths
    test "$wrapperStatus" -eq 0
    diff -u <(printf '%s\n' preflight postflight) "$PI_WRAPPER_TEST_PHASES"
    test "$(wc -l <"$PI_WRAPPER_TEST_LAUNCHES")" -eq 1

    : >"$PI_WRAPPER_TEST_PHASES"
    rm -f "$PI_WRAPPER_TEST_ARGUMENTS" "$PI_WRAPPER_TEST_LAUNCHES"
    export PI_WRAPPER_TEST_FAIL_PREFLIGHT=23
    runWrapper must-not-launch
    test "$wrapperStatus" -eq 23
    diff -u <(printf '%s\n' preflight) "$PI_WRAPPER_TEST_PHASES"
    test ! -e "$PI_WRAPPER_TEST_ARGUMENTS"
    test ! -e "$PI_WRAPPER_TEST_LAUNCHES"
    unset PI_WRAPPER_TEST_FAIL_PREFLIGHT

    for behaviorAndStatus in "success 0" "exit 42" "sigint 130" "sigterm 143"; do
      read -r behavior expectedStatus <<<"$behaviorAndStatus"
      : >"$PI_WRAPPER_TEST_PHASES"
      : >"$PI_WRAPPER_TEST_LAUNCHES"
      export PI_WRAPPER_TEST_REAL_PI_BEHAVIOR="$behavior"
      export PI_WRAPPER_TEST_REAL_PI_STATUS="$expectedStatus"
      export PI_WRAPPER_TEST_FAIL_POSTFLIGHT=24
      runWrapper arbitrary-subcommand
      test "$wrapperStatus" -eq "$expectedStatus"
      diff -u <(printf '%s\n' preflight postflight) "$PI_WRAPPER_TEST_PHASES"
      test "$(wc -l <"$PI_WRAPPER_TEST_LAUNCHES")" -eq 1
    done

    unset \
      PI_WRAPPER_TEST_FAIL_POSTFLIGHT \
      PI_WRAPPER_TEST_REAL_PI_BEHAVIOR \
      PI_WRAPPER_TEST_REAL_PI_STATUS
    export HOME="$TMPDIR/integrated home"
    export XDG_CONFIG_HOME="$HOME/config"
    export PI_CODING_AGENT_DIR="$HOME/agent"
    staticSettings="$XDG_CONFIG_HOME/htw/pi-config"
    mkdir -p "$PI_CODING_AGENT_DIR" "$staticSettings"
    printf '%s' '{"fontSize":14,"theme":"light"}' >"$staticSettings/recommended.json"
    printf '%s' '{"telemetry":false}' >"$staticSettings/enforced.json"
    printf '%s' '{"existing":"kept","telemetry":true}' >"$PI_CODING_AGENT_DIR/settings.json"
    printf '%s' 'untouched state' >"$PI_CODING_AGENT_DIR/plugin-state"

    ${integratedWrapper}/bin/pi arbitrary-subcommand

    ${pkgs.jq}/bin/jq -e '
      . == {
        "existing": "kept",
        "fontSize": 14,
        "piChange": "from Pi",
        "telemetry": false,
        "theme": "light"
      }
    ' "$PI_CODING_AGENT_DIR/settings.json" >/dev/null
    ${pkgs.jq}/bin/jq -e '
      . == {
        "existing": "kept",
        "piChange": "from Pi",
        "telemetry": true
      }
    ' "$PI_CODING_AGENT_DIR/.htw-pi-config/local-settings.json" >/dev/null
    ${pkgs.jq}/bin/jq -e '.needsSync == false' \
      "$PI_CODING_AGENT_DIR/.htw-pi-config/needs-sync.json" >/dev/null
    test "$(cat "$PI_CODING_AGENT_DIR/plugin-state")" = "untouched state"

    temporarySettings="$PI_CODING_AGENT_DIR/settings.json.direct"
    ${pkgs.jq}/bin/jq '.directChange = "unwrapped"' \
      "$PI_CODING_AGENT_DIR/settings.json" >"$temporarySettings"
    mv "$temporarySettings" "$PI_CODING_AGENT_DIR/settings.json"

    ${integratedWrapper}/bin/pi second-invocation

    ${pkgs.jq}/bin/jq -e '
      .directChange == "unwrapped" and
      .piChange == "from Pi" and
      .telemetry == false
    ' "$PI_CODING_AGENT_DIR/settings.json" >/dev/null
    ${pkgs.jq}/bin/jq -e '
      .directChange == "unwrapped" and
      .piChange == "from Pi" and
      .telemetry == true
    ' "$PI_CODING_AGENT_DIR/.htw-pi-config/local-settings.json" >/dev/null
    test "$(cat "$PI_CODING_AGENT_DIR/plugin-state")" = "untouched state"

    export PI_WRAPPER_TEST_MALFORM_LIVE=1
    ${integratedWrapper}/bin/pi malformed-live
    ${pkgs.jq}/bin/jq -e '.needsSync == true' \
      "$PI_CODING_AGENT_DIR/.htw-pi-config/needs-sync.json" >/dev/null
    test "$(cat "$PI_CODING_AGENT_DIR/settings.json")" = '{"malformed":'
    test "$(cat "$PI_CODING_AGENT_DIR/plugin-state")" = "untouched state"

    touch "$out"
  ''
