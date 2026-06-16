{isDarwin, ...}: {
  imports =
    [
      ./github-runner.nix
      ./tailscale.nix
    ]
    ++ (
      if (!isDarwin)
      then [
        ./fava.nix
        ./moshi.nix
      ]
      else []
    );
}
