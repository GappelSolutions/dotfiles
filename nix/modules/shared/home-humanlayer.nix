{ pkgs, ... }:

{
  systemd.user.services.humanlayer-daemon = {
    Unit = {
      Description = "HumanLayer daemon";
      After = [ "network-online.target" ];
    };
    Service = {
      Environment = "PATH=${pkgs.nodejs}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin";
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec ${pkgs.nodejs}/bin/npx --yes @humanlayer/cli@latest daemon launch --launch-token \"$(cat %h/.config/humanlayer/launch-token)\"'";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
