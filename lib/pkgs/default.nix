{
  pkgs-unstable,
  llm-agents,
}: let
  wp = import ./wrapped-programs.nix {inherit pkgs-unstable llm-agents;};
in {
  inherit (wp) mkWrappedProgram llmApiKeys;
  wrapped-programs = wp.wrappedPrograms;
}
