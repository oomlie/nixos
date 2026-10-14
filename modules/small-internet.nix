{pkgs, ...}: {
  # Gemini server. User capsules are exposed at gemini://gemini.daze.lol/~user/
  # through symlinks maintained by tilde-user-layout.
  services.agate = {
    enable = true;
    addresses = [
      "0.0.0.0:1965"
      "[::]:1965"
    ];
    hostnames = ["gemini.daze.lol"];
    contentDir = "/var/lib/agate/content";
    certificatesDir = "/var/lib/agate/certificates";
    language = "en-US";
    extraArgs = [];
  };

  systemd.services.agate = {
    requires = ["tilde-user-layout.service"];
    after = ["tilde-user-layout.service"];
    serviceConfig = {
      ProtectHome = "read-only";
      ReadOnlyPaths = ["/home"];
    };
  };

  users.users.gopher = {
    isSystemUser = true;
    group = "gopher";
    home = "/var/lib/gopher";
  };
  users.groups.gopher = {};

  # geomyidae serves static Gopher content only; -e disables CGI/DCGI.
  systemd.services.geomyidae = {
    description = "daze.lol Gopher server";
    requires = ["tilde-user-layout.service"];
    after = [
      "network.target"
      "tilde-user-layout.service"
    ];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "gopher";
      Group = "gopher";
      ExecStart = "${pkgs.geomyidae}/bin/geomyidae -4 -d -e -b /var/lib/gopher -p 70 -h gopher.daze.lol";
      AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
      CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
      StateDirectory = "gopher";
      StateDirectoryMode = "0755";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      ReadOnlyPaths = ["/home"];
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
    };
  };
}
