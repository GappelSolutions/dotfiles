{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      "dart-lang/dart"
      "nikitabobko/tap"
    ];

    brews = [
      "neovim-remote" # nvr for neovim
      "cocoapods" # ios deps
      "azure-cli" # nix version triggers Swift build
      "elixir"
      "helm"
      "k9s"
      "podman"
      "podman-compose"
      "minikube"
      "postgresql@14"
      "libpq"
      "redis"
    ];

    casks = [
      "zen"
      "alacritty"
      "aerospace"
      "jordanbaird-ice"
      "dotnet-sdk"
      "android-studio"
      "android-platform-tools"
      "flutter"
      "postman"
      # "ngrok" # temporarily disabled - SSL cert issue on their CDN
      "cursor"
      "obsidian"
      "karabiner-elements" # driver only - needed for kanata
      "raycast"
      "keka"
      "localsend"
      "balenaetcher"
      "flameshot"
      "tailscale"
      "font-fira-code-nerd-font"
      "font-sf-mono"
      "font-sf-pro"
      "sf-symbols"
      "master-pdf-editor"
      "thunderbird"
      "microsoft-outlook"
      "microsoft-remote-desktop"
      "microsoft-auto-update"
      "wine-stable"
      "gstreamer-runtime"
    ];
  };
}
