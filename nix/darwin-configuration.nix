{ config, pkgs, inputs, ... }:

{
  # ==========================================================================
  # Nix Settings
  # ==========================================================================
  # Disabled because we use Determinate Nix installer which manages its own daemon
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # System Packages (available system-wide)
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # ==========================================================================
  # Homebrew (for casks and some formulae not in nixpkgs)
  # ==========================================================================
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # removes unlisted casks/formulae
      upgrade = true;
    };

    taps = [
      "homebrew/bundle"
      "dart-lang/dart"
    ];

    # CLI tools that work better via Homebrew or aren't in nixpkgs
    brews = [
      "neovim-remote"     # nvr for neovim
      "bob"               # neovim version manager
      "mas"               # mac app store cli
      "cocoapods"         # ios deps
      "nowplaying-cli"    # music info
    ];

    # GUI applications
    casks = [
      # Terminal
      "alacritty"

      # Window Management
      "aerospace"
      "karabiner-elements"
      "jordanbaird-ice"

      # Development
      "android-studio"
      "android-platform-tools"
      "flutter"
      "postman"
      "ngrok"

      # Editors
      "obsidian"

      # Utilities
      "appcleaner"
      "keka"
      "localsend"
      "balenaetcher"
      "flameshot"

      # Fonts
      "font-fira-code-nerd-font"
      "font-hack-nerd-font"
      "font-sf-mono"
      "font-sf-pro"
      "sf-symbols"

      # PDF & Docs
      "master-pdf-editor"
      "basictex"

      # Communication
      "thunderbird"

      # Microsoft
      "microsoft-outlook"
      "microsoft-remote-desktop"
      "microsoft-auto-update"

      # Misc
      "wine-stable"
      "gstreamer-runtime"
    ];
  };

  # ==========================================================================
  # macOS System Defaults
  # ==========================================================================
  system.defaults = {
    # Finder
    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXEnableExtensionChangeWarning = false;
    };

    # Dock
    dock = {
      autohide = false;
      show-recents = false;
      mru-spaces = false;
    };

    # Keyboard
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;  # disable for vim key repeat
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleShowAllExtensions = true;
    };

    # Trackpad
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  # ==========================================================================
  # Security
  # ==========================================================================
  security.pam.services.sudo_local.touchIdAuth = true;

  # ==========================================================================
  # Primary User (required for homebrew and user defaults)
  # ==========================================================================
  system.primaryUser = "cgpp";

  # ==========================================================================
  # Services
  # ==========================================================================
  # Add any launchd services here if needed
  # services.yabai.enable = true;

  # ==========================================================================
  # Agenix Secrets
  # ==========================================================================
  age.identityPaths = [
    "/Users/cgpp/.age/master.key"
  ];

  age.secrets = {
    ssh-github-personal = {
      file = ./secrets/ssh-github-personal.age;
      path = "/Users/cgpp/.ssh/id_ed25519";
      owner = "cgpp";
      mode = "600";
    };
    ssh-github-work = {
      file = ./secrets/ssh-github-work.age;
      path = "/Users/cgpp/.ssh/id_ed25519_work";
      owner = "cgpp";
      mode = "600";
    };
    ssh-azure = {
      file = ./secrets/ssh-azure.age;
      path = "/Users/cgpp/.ssh/id_azure_rsa";
      owner = "cgpp";
      mode = "600";
    };
  };

  # ==========================================================================
  # System State Version
  # ==========================================================================
  system.stateVersion = 4;

  # User configuration
  users.users.cgpp = {
    name = "cgpp";
    home = "/Users/cgpp";
  };
}
