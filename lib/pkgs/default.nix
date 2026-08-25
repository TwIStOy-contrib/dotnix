{
  pkgs-unstable,
  llm-agents,
  dotvim-ne,
  htw,
}: let
  wp = import ./wrapped-programs.nix {inherit pkgs-unstable llm-agents dotvim-ne htw;};
in {
  inherit (wp) mkWrappedProgram llmApiKeys;
  wrapped-programs = wp.wrappedPrograms;
}
