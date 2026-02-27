{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    gnugrep
    gnutar
    fish
  ];

  programs.zsh.enable = true;
  environment.shells = with pkgs; [
    zsh
    fish
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
    ];

    casks = [
      "1password"
      "1password-cli"
      "iina"
      "arc"
      "google-chrome"
      "visual-studio-code"
      "karabiner-elements"
      "jetbrains-toolbox"
      "neovide"
      "wireshark"
      "kitty"
      "xquartz"
      "devpod"
      "follow"
      "raycast"
      "orbstack"
      "obsidian"
      "ghostty"
      "neteasemusic"
      "finetune"
    ];
  };
}
