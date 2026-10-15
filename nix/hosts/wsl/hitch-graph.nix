{ pkgs, ... }:

let
  draw = pkgs.writers.writePython3Bin "hitch-graph-draw" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ../../scripts/hitch-graph-draw.py);
  hitch-graph = pkgs.writeShellApplication {
    name = "hitch-graph";
    # az comes from the user profile.
    runtimeInputs = with pkgs; [ coreutils curl jq gnused ] ++ [ draw ];
    text = builtins.readFile ../../scripts/hitch-graph;
  };
in
{
  home.packages = [ hitch-graph ];

  systemd.user.services.hitch-graph = {
    Unit = {
      Description = "Draw one Excalidraw dependency graph of all active hitch Features into the Obsidian vault";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${hitch-graph}/bin/hitch-graph";
    };
  };

  systemd.user.timers.hitch-graph = {
    Unit = {
      Description = "hitch-graph every 10 minutes";
    };
    Timer = {
      OnCalendar = "*:0/10";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
