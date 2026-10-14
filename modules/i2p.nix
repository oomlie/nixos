_: {
  # i2pd: I2P router. Server node (reachable via port 4567) hosting an eepsite.
  services.i2pd = {
    enable = true;
    settings = {
      # Keep the home uplink usable.
      bandwidth = 256;
      ipv4 = true;
      ipv6 = false;
      nat = true;
      notransit = false;
      http = {
        enabled = true; # web console
        address = "127.0.0.1";
        port = 7070;
      };
      httpproxy = {
        enabled = true;
        address = "127.0.0.1";
        port = 4444;
      };
      socksproxy = {
        enabled = true;
        address = "127.0.0.1";
        port = 4447;
      };
      sam.enabled = false;
    };

    # Serves the tilde landing page from Caddy's internal listener.
    serverTunnels.tilde = {
      type = "server";
      host = "127.0.0.1";
      port = 8081;
      inport = 80;
      keys = "tilde-keys.dat";
    };

    # Deferred: a SearXNG eepsite needs a second searx instance whose base_url
    # is the generated .b32.i2p address (chicken-and-egg with the keys file).
    # Add `serverTunnels.searx = { host = "127.0.0.1"; port = 3017; inport = 80; };`
    # plus a dedicated searx instance on 3017 when that is wanted.
  };

  # Internal catch-all HTTP listener for the tilde eepsite. Caddy's public
  # vhosts are hostname-bound, so i2p requests (Host: <b32>.i2p) land here.
  services.caddy.virtualHosts."http://127.0.0.1:8081" = {
    extraConfig = ''
      root * /var/www/tilde
      file_server
    '';
  };
}
