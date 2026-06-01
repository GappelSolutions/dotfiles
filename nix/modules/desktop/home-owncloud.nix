{ config, pkgs, ... }:

let
  envFile = "${config.home.homeDirectory}/.config/owncloud/owncloud.env";
in
{
  home.packages = [
    pkgs.owncloud-client
  ];

  home.activation.createOwncloudConfig =
    config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
      mkdir -p ${config.home.homeDirectory}/.config/owncloud
      mkdir -p ${config.home.homeDirectory}/ownCloud
      chmod 700 ${config.home.homeDirectory}/.config/owncloud
      if [ ! -e ${envFile} ]; then
        umask 077
        {
          printf '%s\n' 'OWNCLOUD_SERVER_URL=https://cloud.gappel.com'
          printf '%s\n' 'OWNCLOUD_REMOTE_FOLDER=/'
          printf '%s\n' 'OWNCLOUD_LOCAL_DIR=${config.home.homeDirectory}/ownCloud'
          printf '%s\n' 'OWNCLOUD_USERNAME=cgpp-admin'
          printf '%s\n' 'OWNCLOUD_PASSWORD='
        } > ${envFile}
      fi
      chmod 600 ${envFile}
    '';

  systemd.user.services.owncloud-sync = {
    Unit = {
      Description = "Sync ownCloud files";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      EnvironmentFile = envFile;
      ExecStart = toString (pkgs.writeShellScript "owncloud-sync" ''
        set -euo pipefail

        mkdir -p "$OWNCLOUD_LOCAL_DIR"
        exec ${pkgs.owncloud-client}/bin/owncloudcmd \
          --non-interactive \
          --trust \
          --user "$OWNCLOUD_USERNAME" \
          --password "$OWNCLOUD_PASSWORD" \
          "$OWNCLOUD_LOCAL_DIR" \
          "$OWNCLOUD_SERVER_URL" \
          "$OWNCLOUD_REMOTE_FOLDER"
      '');
    };
  };

  systemd.user.timers.owncloud-sync = {
    Unit.Description = "Run ownCloud sync periodically";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "15min";
      Persistent = true;
      Unit = "owncloud-sync.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
