{
  pkgs-unstable,
  llm-agents,
  dotvim-ne,
}: let
  wp = import ./wrapped-programs.nix {inherit pkgs-unstable llm-agents dotvim-ne;};
  et = import ./et.nix {inherit pkgs-unstable;};
in {
  inherit (wp) mkWrappedProgram llmApiKeys;
  wrapped-programs = wp.wrappedPrograms;
  inherit (et) eternal-terminal-master;
}
