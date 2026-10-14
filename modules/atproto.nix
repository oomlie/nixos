{config, ...}: {
  # Tranquil PDS (Rust ATProto PDS).
  services.tranquil-pds = {
    enable = true;
    database.createLocally = true;
    environmentFiles = [config.sops.secrets."pds-env".path];
    settings = {
      server = {
        hostname = "pds.daze.lol";
        host = "127.0.0.1";
        port = 3000;
        user_handle_domains = ["daze.lol"];
      };
      frontend.enabled = true;
    };
  };

  # Tangled knot (git server).
  services.tangled.knot = {
    enable = true;
    server = {
      hostname = "knot.daze.lol";
      owner = "did:plc:vtdq3y23vehztw33eohawmpz";
      listenAddr = "127.0.0.1:5555";
    };
  };

  # Tangled spindle (CI runner).
  services.tangled.spindle = {
    enable = true;
    server = {
      hostname = "spindle.daze.lol";
      owner = "did:plc:vtdq3y23vehztw33eohawmpz";
      listenAddr = "127.0.0.1:6555";
    };
  };

  sops.secrets."pds-env" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["tranquil-pds.service"];
  };
}
