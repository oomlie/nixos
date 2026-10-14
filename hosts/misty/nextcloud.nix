{
  config,
  myceliumAddresses,
  pkgs,
  ...
}: {
  sops.secrets."nextcloud/admin-password" = {
    sopsFile = ../../secrets/misty.yaml;
    mode = "0400";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud34;
    hostName = "cloud.daze.lol";
    https = true;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminuser = "molly";
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
    };
    settings = {
      overwriteprotocol = "https";
      "overwrite.cli.url" = "https://cloud.daze.lol";
      trusted_proxies = [myceliumAddresses.halo];
      default_phone_region = "US";
    };
  };

  services.nginx.defaultHTTPListenPort = 8081;
  networking.firewall.interfaces.mycelium.allowedTCPPorts = [8081];
}
