{
  config,
  pkgs,
  ...
}: let
  holdConfig = pkgs.writeText "hold-config.yml" ''
    version: "0.1"
    log_level: info

    storage:
      region: garage
      bucket: atcr-blobs
      endpoint: http://127.0.0.1:3900
      pull_zone: https://cdn.daze.lol

    server:
      addr: ":8091"
      public_url: https://hold.daze.lol
      public: true
      appview_did: did:web:atcr.io

    registration:
      owner_did: did:plc:vtdq3y23vehztw33eohawmpz

    database:
      path: /var/lib/atcr-hold
      did_method: plc
      did: did:plc:vtdq3y23vehztw33eohawmpz

    admin:
      enabled: false
  '';
in {
  # Garage: private S3-compatible object store backing Hold.
  # Alternative: skip Garage and point Hold at any existing S3 provider by
  # changing the storage.endpoint/region below and reusing the same env files.
  services.garage = {
    enable = true;
    package = pkgs.garage;
    environmentFile = "/run/garage-rpc.env";
    settings = {
      metadata_dir = "/var/lib/garage/meta";
      data_dir = "/var/lib/garage/data";
      db_engine = "sqlite";
      replication_factor = 1;
      rpc_bind_addr = "127.0.0.1:3901";
      rpc_public_addr = "127.0.0.1:3901";
      s3_api = {
        api_bind_addr = "127.0.0.1:3900";
        s3_region = "garage";
        root_domain = ".daze.lol";
      };
      admin.api_bind_addr = "127.0.0.1:3903";
    };
  };

  # Garage RPC secret: materialized as a root-readable env file for PID1.
  systemd.services.garage-rpc-env = {
    before = ["garage.service"];
    requiredBy = ["garage.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'GARAGE_RPC_SECRET=%s\n' "$(cat ${config.sops.secrets."garage/rpc-secret".path})" >/run/garage-rpc.env
    '';
  };

  # Hold (ATCR): ATProto OCI container registry backed by Garage.
  systemd.services.hold-env = {
    before = ["podman-hold.service"];
    requiredBy = ["podman-hold.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      {
        printf 'AWS_ACCESS_KEY_ID=%s\n' "$(cat ${config.sops.secrets."garage/s3-access".path})"
        printf 'AWS_SECRET_ACCESS_KEY=%s\n' "$(cat ${config.sops.secrets."garage/s3-secret".path})"
        printf 'HOLD_DATABASE_ROTATION_KEY=%s\n' "$(cat ${config.sops.secrets."hold/rotation-key".path})"
      } >/run/hold.env
    '';
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.hold = {
      # pin: docker login atcr.io && skopeo inspect docker://atcr.io/cove.town/hold --format '{{.Digest}}'
      image = "atcr.io/cove.town/hold";
      ports = ["127.0.0.1:8091:8091"];
      cmd = ["serve" "--config" "/config.yml"];
      volumes = [
        "hold-data:/var/lib/atcr-hold"
        "${holdConfig}:/config.yml:ro"
      ];
      environmentFiles = ["/run/hold.env"];
      autoStart = true;
    };
  };

  sops.secrets."garage/rpc-secret" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["garage.service"];
  };
  sops.secrets."garage/s3-access" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["podman-hold.service"];
  };
  sops.secrets."garage/s3-secret" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["podman-hold.service"];
  };
  sops.secrets."hold/rotation-key" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["podman-hold.service"];
  };
}
