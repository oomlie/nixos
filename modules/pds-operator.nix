{
  config,
  pdsOperator,
  ...
}: {
  users.users.pds-operator = {
    isSystemUser = true;
    group = "pds-operator";
  };
  users.groups.pds-operator = {};

  systemd.services.pds-operator = {
    description = "PDS Operator (atproto admin dashboard)";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      NODE_ENV = "production";
      HOST = "127.0.0.1";
      PORT = "8787";
      PDS_HOSTNAME = "pds.daze.lol";
      # tranquil-pds has no admin password: sign in as an admin account instead.
      # Account created under the current MASTER_KEY (older accounts such as
      # taskdoer.daze.lol can no longer be decrypted).
      PDS_ADMIN_IDENTIFIER = "tranquilops.daze.lol";
      RELAY_HOSTNAME = "bsky.network";
      APPVIEW_URL = "https://bsky.app";
      DASHBOARD_URL = "https://pds-admin.daze.lol";
      DB_PATH = "/var/lib/pds-operator/data.sqlite";
      AUDIT_LOG_PATH = "/var/lib/pds-operator/audit.log";
    };
    serviceConfig = {
      ExecStart = "${pdsOperator}/bin/pds-operator";
      User = "pds-operator";
      Group = "pds-operator";
      StateDirectory = "pds-operator";
      EnvironmentFile = "/run/pds-operator.env";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictSUIDSGID = true;
    };
  };

  # The service runs unprivileged, so PID1 reads the secrets and materializes the
  # env file (same pattern as vikunja-oidc-env).
  systemd.services.pds-operator-env = {
    before = ["pds-operator.service"];
    requiredBy = ["pds-operator.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      {
        printf 'SESSION_SECRET=%s\n' "$(cat ${config.sops.secrets."pds-operator/session-secret".path})"
        printf 'PDS_ADMIN_PASSWORD=%s\n' "$(cat ${config.sops.secrets."pds-operator/admin-password".path})"
      } >/run/pds-operator.env
    '';
  };

  sops.secrets."pds-operator/session-secret" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = [
      "pds-operator-env.service"
      "pds-operator.service"
    ];
  };
  sops.secrets."pds-operator/admin-password" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = [
      "pds-operator-env.service"
      "pds-operator.service"
    ];
  };
}
