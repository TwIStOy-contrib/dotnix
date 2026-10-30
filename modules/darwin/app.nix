{
  pkgs,
  pkgs-unstable,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    gnugrep
    gnutar
    pkgs-unstable.fish
  ];

  programs.zsh.enable = true;
  environment.shells = with pkgs; [
    zsh
    pkgs-unstable.fish
    iproute2mac
  ];

  homebrew = {
    enable = false;

    onActivation = {
      autoUpdate = true;
      upgrade = true;

      cleanup = "none";
    };

    masApps = {
      "Nook X" = 6733240772;
      "Wechat" = 836500024;
    };

    taps = [
      "homebrew/services"
      "osx-cross/avr"
      "osx-cross/arm"
      "leoafarias/fvm"
      "qmk/qmk"
      "FelixKratz/formulae"
      "d12frosted/emacs-plus"
      "nikitabobko/tap"
    ];

    brews = [
      "wget"
      "curl"
      "aria2"
      "httpie"

      "gnu-sed"
      "gnu-tar"
      "jq"

      # xcode related tools
      # "xcbeautify" # beautifier tool for xcodebuild
      # "xcode-build-server" # xcodeproject to lspconfigs
      "swift-format"
      "emacs-plus"

      "mas"

      # virtualisation
      "qemu"
    ];

    casks = [
      "1password"
      "1password-cli"
      "arc"
      "devpod"
      "finetune"
      "follow"
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "iina"
      "jetbrains-toolbox"
      "karabiner-elements"
      "kitty"
      "neovide"
      "neteasemusic"
      "obsidian"
      "orbstack"
      "raycast"
      "terminal-browser"
      "visual-studio-code"
      "wireshark"
      "xquartz"
    ];
  };
}
