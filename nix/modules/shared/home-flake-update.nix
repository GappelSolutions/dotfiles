{ pkgs, ... }:

let
  update-flake-lock = pkgs.writeShellApplication {
    name = "update-flake-lock";
    runtimeInputs = with pkgs; [ git nix nixos-rebuild coreutils hostname sudo ];
    text = builtins.readFile ../../scripts/update-flake-lock;
  };
in
{
  home.packages = [ update-flake-lock ];

  systemd.user.services.update-flake-lock = {
    Unit = {
      Description = "Bump dotfiles flake.lock, build, and switch if it builds cleanly (passwordless sudo; rollback with 'rollback' alias)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${update-flake-lock}/bin/update-flake-lock";
    };
  };

  systemd.user.timers.update-flake-lock = {
    Unit = {
      Description = "Daily dotfiles flake.lock update check";
    };
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
