{ pkgs, ... }:

let
  claude-limit-resume = pkgs.writers.writePython3Bin "claude-limit-resume" {
    flakeIgnore = [ "E" "W" ];
  } (builtins.readFile ../../scripts/claude-limit-resume);
in
{
  home.packages = [ claude-limit-resume ];

  systemd.user.services.claude-limit-resume = {
    Unit = {
      Description = "Resume T3 Code threads stopped on a Claude usage limit once it has reset";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${claude-limit-resume}/bin/claude-limit-resume";
    };
  };

  systemd.user.timers.claude-limit-resume = {
    Unit = {
      Description = "Check every 10 minutes for T3 threads to resume after a usage limit";
    };
    Timer = {
      OnCalendar = "*:0/10";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
