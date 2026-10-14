# Serve Bluesky profile pictures for Navidrome's user avatar.
#
# Navidrome 0.64 has no OIDC and no avatar upload, so its /rest/getAvatar
# returns a placeholder. Caddy on halo points that path at this shim, which
# resolves the ATProto DID (the Navidrome username from ratlogin's
# reverse-proxy auth) to the account's Bluesky avatar.
{
  myceliumAddresses,
  pkgs,
  ...
}: let
  port = 4191;
  script = pkgs.writeText "bluesky-avatar.mjs" (builtins.readFile ./bluesky-avatar.mjs);
in {
  systemd.services.bluesky-avatar = {
    description = "Bluesky avatar shim for Navidrome";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      PORT = toString port;
      NAVIDROME = "http://[${myceliumAddresses.misty}]:4533";
    };
    serviceConfig = {
      ExecStart = "${pkgs.nodejs}/bin/node ${script}";
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      CapabilityBoundingSet = "";
      # AF_NETLINK for DNS/interface lookup, AF_INET/AF_INET6 to reach the
      # AppView, the CDN, and Navidrome over Mycelium.
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK"];
    };
  };
}
