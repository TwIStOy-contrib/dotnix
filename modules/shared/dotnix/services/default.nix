{isDarwin, ...}: {
  imports =
    [
      ./github-runner.nix
      ./htw.nix
      ./tailscale.nix
    ]
    ++ (
      if (!isDarwin)
      then [
        ./fava.nix
      ]
      else []
    );
}
