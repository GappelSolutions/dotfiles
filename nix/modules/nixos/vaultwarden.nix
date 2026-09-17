{ config, lib, pkgs, ... }:

let
  cfg = config.services.vaultwarden;
  domain = cfg.publicDomain;
  certDir = "/var/lib/vaultwarden-tls";
in
{
  options.services.vaultwarden.rocketPort = lib.mkOption {
    type = lib.types.port;
    default = 8222;
    description = "Internal port vaultwarden listens on, proxied by nginx.";
  };

  options.services.vaultwarden.publicDomain = lib.mkOption {
    type = lib.types.str;
    default = config.networking.hostName;
    description = "Hostname or IP used for the self-signed cert CN/SAN and nginx vhost. Set explicitly when there's no DNS record for the hostname.";
  };

  config = {
    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://${domain}";
        SIGNUPS_ALLOWED = true;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = cfg.rocketPort;
      };
    };

    systemd.services.vaultwarden-selfsigned-cert = {
      description = "Generate self-signed TLS cert for vaultwarden";
      wantedBy = [ "nginx.service" ];
      before = [ "nginx.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p ${certDir}
        if [ ! -f ${certDir}/cert.pem ]; then
          ${pkgs.openssl}/bin/openssl req -x509 -nodes -newkey rsa:2048 \
            -keyout ${certDir}/key.pem \
            -out ${certDir}/cert.pem \
            -days 3650 -subj "/CN=${domain}" \
            -addext "subjectAltName=DNS:${domain}"
        fi
        chown root:${config.services.nginx.group} ${certDir}/key.pem
        chmod 640 ${certDir}/key.pem
        chmod 755 ${certDir}
      '';
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        forceSSL = true;
        sslCertificate = "${certDir}/cert.pem";
        sslCertificateKey = "${certDir}/key.pem";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.rocketPort}";
          proxyWebsockets = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
