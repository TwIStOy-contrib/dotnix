{
  pkgs-unstable,
  llm-agents,
}: let
  wp = import ./wrapped-programs.nix {inherit pkgs-unstable llm-agents;};
in {
  inherit (wp) mkWrappedProgram;
  wrapped-programs = wp.wrappedPrograms;
}
