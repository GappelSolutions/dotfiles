{ pkgs, ... }:

let
  update-aoe = pkgs.writeShellApplication {
    name = "update-aoe";
    runtimeInputs = with pkgs; [ curl gnugrep gnused gawk nix coreutils ];
    text = builtins.readFile ../../scripts/update-aoe;
  };
in
{
  home.packages = [ update-aoe ];

  systemd.user.services.update-aoe = {
    Unit = {
      Description = "Check for agent-of-empires updates and bump package.nix";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${update-aoe}/bin/update-aoe";
    };
  };

  systemd.user.timers.update-aoe = {
    Unit = {
      Description = "Weekly agent-of-empires update check";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
