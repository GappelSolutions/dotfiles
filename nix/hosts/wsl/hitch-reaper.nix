{ pkgs, ... }:

let
  hitch-reaper = pkgs.writeShellApplication {
    name = "hitch-reaper";
    # oc, az and claude come from the user profile and ~/.local/bin.
    runtimeInputs = with pkgs; [ coreutils util-linux jq gnugrep gawk findutils git ];
    text = builtins.readFile ../../scripts/hitch-reaper;
  };
in
{
  home.packages = [ hitch-reaper ];

  systemd.user.services.hitch-reaper = {
    Unit = {
      Description = "Release stale hitch dev-namespace leases and run After merge for merged Tasks no session closed";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${hitch-reaper}/bin/hitch-reaper";
    };
  };

  systemd.user.timers.hitch-reaper = {
    Unit = {
      Description = "hitch-reaper every 10 minutes";
    };
    Timer = {
      OnCalendar = "*:0/10";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
