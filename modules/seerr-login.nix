# Inject a Quick-Connect explainer + login-page cleanup into Seerr's HTML.
#
# Seerr has no login-message/custom-CSS option and renders its login UI in
# JS, so this proxy injects a small script (banner + hide non-Quick-Connect
# controls). Best-effort: it depends on Seerr's DOM text labels.
{
  myceliumAddresses,
  pkgs,
  ...
}: let
  port = 4192;
  script = pkgs.writeText "seerr-login.mjs" (builtins.readFile ./seerr-login.mjs);
in {
  systemd.services.seerr-login = {
    description = "Seerr login-page shim";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      PORT = toString port;
      UPSTREAM = "http://[${myceliumAddresses.misty}]:5055";
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
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK"];
    };
  };
}
