{pkgs-unstable}: let
  # nixpkgs unstable still packages eternal-terminal from the et-v7.0.0 tag,
  # whose CMakeLists pins C++17. Protobuf >= 36 pulls Abseil LTS 20260817,
  # which sets ABSL_OPTION_USE_STD_ORDERING=1 and therefore requires C++20:
  # compiling 7.0.0 as C++17 fails on the missing std::strong_ordering family
  # (dotnix CI PR #75 failure). Upstream fixed this on master (12889c5b,
  # 2026-07-21) but has not tagged a release after 7.0.0, so pin master here.
  # Drop this override once unstable ships et with CMAKE_CXX_STANDARD >= 20
  # (nixpkgs PR #569401 tracks the fix).
  eternal-terminal-master = pkgs-unstable.eternal-terminal.overrideAttrs (old: {
    src = pkgs-unstable.fetchgit {
      url = "https://github.com/MisterTea/EternalTerminal";
      rev = "5129342ef5ce3185125d907b95ad6d15a36b1cb6";
      hash = "sha256-jiUMENmq1sMPAMfaM7LRBijOhYXiQgK40dcsNOdtZgg=";
      # master renamed external_imported -> external and keeps its
      # dependencies as real submodules; the 7.0.0 tag had them committed,
      # so the plain tarball fetch the nixpkgs recipe relies on would leave
      # them empty.
      fetchSubmodules = true;
    };
    # recipe's preBuild copies the packaged Catch2 v2 single-include header
    # into external_imported; master vendors Catch2 v3 itself.
    preBuild = "";
    # PTY/ssh system tests fail only inside the nix build sandbox (they need
    # a normal runner, not the sandbox); upstream CI on this exact commit is
    # green across gcc 13-16 and sanitizers. LargeInputNoDeadlock is the
    # flaky test upstream nixpkgs already excludes.
    checkPhase = ''
      ctest --output-on-failure -E 'et-test\.(LargeInputNoDeadlock|RouterRestartRealPtySurvives|et -G -F -o prints resolved keywords without connecting|et -G applies -o Hostname/User with spaces around =|Control-mode PTY: SIGKILL of htm lets htmd accept a new client|Control-mode PTY: detach leaves htmd running|sessionHasEnded without master EOF while descendant holds PTY slave)'
    '';
    # master's project() still reports 7.0.0, so the recipe's versionCheckHook
    # keeps passing untouched.
    meta =
      (old.meta or {})
      // {
        # master is untagged; the recipe's changelog URL only covers releases.
        changelog = "https://github.com/MisterTea/EternalTerminal/commits/master";
      };
  });
in {
  inherit eternal-terminal-master;
}
