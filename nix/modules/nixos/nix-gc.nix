{
  # Every rebuild keeps the previous closure alive; without GC, WSL hit
  # 228 generations / ~250G before anyone noticed.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings.auto-optimise-store = true;
}
