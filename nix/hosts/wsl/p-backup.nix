{ pkgs, ... }:

let
  p-backup = pkgs.writeShellApplication {
    name = "p-backup";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ../../scripts/p-backup;
  };
in
{
  home.packages = [ p-backup ];

  systemd.user.services.p-backup = {
    Unit = {
      Description = "Mirror the Obsidian vault and ~/.hitch to P:\\backup (once per day, when P: is reachable)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${p-backup}/bin/p-backup";
    };
  };

  systemd.user.timers.p-backup = {
    Unit = {
      Description = "Hourly check for the daily P: backup";
    };
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
