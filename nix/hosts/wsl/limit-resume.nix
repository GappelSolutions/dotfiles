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
      Description = "Resume Claude Code sessions stopped on a Claude usage limit once it has reset";
    };
    Service = {
      Type = "oneshot";
      Environment = "PATH=/run/wrappers/bin:%h/.local/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin";
      ExecStart = "${claude-limit-resume}/bin/claude-limit-resume";
    };
  };

  systemd.user.timers.claude-limit-resume = {
    Unit = {
      Description = "Check every 10 minutes for Claude sessions to resume after a usage limit";
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
