{
  config,
  lib,
  ...
}: let
  acmeDir = config.security.acme.certs."irc.daze.lol".directory;
in {
  users.users.soju = {
    isSystemUser = true;
    group = "soju";
  };
  users.groups.soju = {};

  # TLS for the raw IRC socket must come from ACME DNS-01 (Caddy only issues
  # HTTP-01, and port 80 is already Caddy's).
  security.acme = {
    acceptTerms = true;
    certs."irc.daze.lol" = {
      dnsProvider = "cloudflare";
      credentialFiles = {
        "CF_DNS_API_TOKEN_FILE" = config.sops.secrets."acme/cloudflare".path;
      };
      group = "soju";
      postRun = "systemctl reload soju";
    };
  };

  services.soju = {
    enable = true;
    hostName = "irc.daze.lol";
    listen = [
      ":6697"
      "ws://localhost:8818"
    ];
    httpOrigins = ["https://irc.daze.lol"];
    acceptProxyIP = ["localhost"];
    extraConfig = ''
      tls ${acmeDir}/fullchain.pem ${acmeDir}/key.pem
      db sqlite3 /var/lib/soju/main.db
    '';
  };

  # soju's module uses DynamicUser; the ACME cert/key are group-owned by the
  # static `soju` group, so run soju as that static user instead.
  systemd.services.soju.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "soju";
    Group = "soju";
  };

  sops.secrets."acme/cloudflare" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["acme-irc.daze.lol.service"];
  };
}
