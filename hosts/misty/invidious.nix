# Invidious (OIDC fork) on misty, plus its companion and PostgreSQL.
# The instance is gated to ratlogin: everything redirects to /oidc/login
# and the local password form is hidden (oidc_only + private_instance).
{
  config,
  invidiousOidc,
  myceliumAddresses,
  pkgs,
  ...
}: let
  host = "yt.daze.lol";
in {
  services.postgresql = {
    enable = true;
    # crystal-pg cannot use unix-socket URIs, so Invidious connects over
    # localhost TCP. Only 127.0.0.1/::1 are reachable (the firewall blocks
    # 5432), so trust is confined to the host.
    authentication = ''
      local all all peer
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    ensureDatabases = ["invidious"];
    ensureUsers = [
      {
        name = "invidious";
        ensureDBOwnership = true;
      }
    ];
  };

  users.groups.invidious = {};
  users.users.invidious = {
    isSystemUser = true;
    group = "invidious";
  };

  sops.secrets = {
    "invidious/hmac-key" = {
      sopsFile = ../../secrets/misty.yaml;
      owner = "invidious";
      mode = "0400";
      restartUnits = ["invidious.service"];
    };
    "invidious/companion-key" = {
      sopsFile = ../../secrets/misty.yaml;
      owner = "invidious";
      mode = "0400";
      restartUnits = [
        "invidious.service"
        "podman-invidious-companion.service"
      ];
    };
    "oidc/invidious" = {
      sopsFile = ../../secrets/misty.yaml;
      owner = "invidious";
      mode = "0400";
      restartUnits = ["invidious.service"];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/invidious 0750 invidious invidious -"
    "d /var/tmp/youtubei.js 0750 65534 65534 -"
  ];

  # Invidious has no NixOS module; render its config from the sops secrets.
  systemd.services.invidious-config = {
    before = ["invidious.service"];
    requiredBy = ["invidious.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      cat > /run/invidious-config.yml <<EOF
      database_url: "postgres://invidious@127.0.0.1:5432/invidious"
      domain: ${host}
      https_only: true
      external_port: 443
      check_tables: true
      hmac_key: "$(cat ${config.sops.secrets."invidious/hmac-key".path})"
      registration_enabled: false
      oidc_issuer: "https://auth.daze.lol"
      oidc_client_id: "invidious"
      oidc_client_secret: "$(cat ${config.sops.secrets."oidc/invidious".path})"
      oidc_only: true
      oidc_auto_provision: true
      oidc_display_name: "ratlogin"
      oidc_claim: email
      private_instance: true
      modified_source_code_url: "https://github.com/DanieleS/invidious"
      invidious_companion:
        - private_url: "http://127.0.0.1:8282/companion"
      invidious_companion_key: "$(cat ${config.sops.secrets."invidious/companion-key".path})"
      EOF
      chown invidious:invidious /run/invidious-config.yml
      chmod 0400 /run/invidious-config.yml
    '';
  };

  systemd.services.invidious = {
    description = "Invidious";
    after = [
      "network-online.target"
      "postgresql.service"
      "podman-invidious-companion.service"
    ];
    wants = ["network-online.target"];
    requires = ["invidious-config.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "invidious";
      Group = "invidious";
      ExecStart = "${pkgs.bash}/bin/bash -c 'export INVIDIOUS_CONFIG=\"$(cat /run/invidious-config.yml)\"; exec ${invidiousOidc}/bin/invidious'";
      Restart = "on-failure";
      RestartSec = "10s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ReadWritePaths = ["/var/lib/invidious"];
    };
  };

  # Invidious listens on IPv4 only; expose it to halo over Mycelium.
  systemd.sockets.invidious-mycelium = {
    wantedBy = ["sockets.target"];
    listenStreams = ["[${myceliumAddresses.misty}]:3000"];
    socketConfig = {
      Accept = false;
      FreeBind = true;
    };
  };
  systemd.services.invidious-mycelium = {
    requires = ["invidious.service"];
    after = ["invidious.service"];
    serviceConfig.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:3000";
  };

  # Companion (Deno) loads the YouTube streams; its secret comes from an
  # environment file rendered here, not from the Nix store.
  systemd.services.invidious-companion-env = {
    before = ["podman-invidious-companion.service"];
    requiredBy = ["podman-invidious-companion.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      {
        echo "SERVER_PORT=8282"
        echo "SERVER_HOST=127.0.0.1"
        echo "SERVER_BASE_PATH=/companion"
        echo "CACHE_DIRECTORY=/var/tmp"
        printf 'SERVER_SECRET_KEY=%s\n' "$(cat ${config.sops.secrets."invidious/companion-key".path})"
      } > /run/invidious-companion.env
    '';
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers.invidious-companion = {
      # ponytail: floating tag; pin a digest once the running version is known.
      image = "quay.io/invidious/invidious-companion:latest";
      environmentFiles = ["/run/invidious-companion.env"];
      volumes = ["/var/tmp/youtubei.js:/var/tmp"];
      # Host networking so it binds 127.0.0.1:8282 for Invidious.
      extraOptions = ["--network=host"];
    };
  };

  networking.firewall.interfaces.mycelium.allowedTCPPorts = [3000];
}
