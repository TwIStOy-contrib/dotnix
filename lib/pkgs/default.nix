{
  pkgs-unstable,
  llm-agents,
  dotvim-ne,
}: let
  wp = import ./wrapped-programs.nix {inherit pkgs-unstable llm-agents dotvim-ne;};
in {
  inherit (wp) mkWrappedProgram llmApiKeys;
  wrapped-programs = wp.wrappedPrograms;
}
