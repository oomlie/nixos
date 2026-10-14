{
  config,
  pkgs,
  ...
}: let
  romm = pkgs.romm.overrideAttrs (old: {
    patches = (old.patches or []) ++ [../patches/romm-oidc-picture.patch];
  });
in {
  services.romm = {
    enable = true;
    package = romm;
    port = 8099;
    nginx.virtualHost = "game.daze.lol";
    environmentFile = "/run/romm-oidc.env";
    extraEnvironment = {
      ROMM_BASE_URL = "https://game.daze.lol";
      ROMM_SESSION_SECURE_COOKIE = "true";
      OIDC_ENABLED = "true";
      OIDC_PROVIDER = "ratlogin";
      OIDC_CLIENT_ID = "romm";
      OIDC_REDIRECT_URI = "https://game.daze.lol/api/oauth/openid";
      OIDC_SERVER_APPLICATION_URL = "https://auth.daze.lol";
      OIDC_USERNAME_ATTRIBUTE = "preferred_username";
      OIDC_CLAIM_ROLES = "groups";
      # ratlogin's groups claim is the user's DID; the admin's DID is admin,
      # every other authenticated member is a regular user.
      OIDC_ROLE_VIEWER = "*";
      OIDC_ROLE_ADMIN = "did:plc:gm5fzdem5pylo2lkgeavgcc5";
      # Hash ROMs in parallel; Halo has 32 cores and the default of 4 starves
      # the initial ~47k-file scan.
      SCAN_WORKERS = "16";
    };
  };

  # nginx serves the RomM frontend and ROM downloads on loopback; Caddy owns
  # 443 and terminates TLS.
  services.nginx.virtualHosts."game.daze.lol".listen = [
    {
      addr = "127.0.0.1";
      port = 8093;
    }
  ];

  # RomM reads the client secret from an environment file, like Vikunja.
  systemd.services.romm-oidc-env = {
    before = ["romm.service"];
    requiredBy = ["romm.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'OIDC_CLIENT_SECRET=%s\n' \
        "$(cat ${config.sops.secrets."oidc/romm".path})" >/run/romm-oidc.env
    '';
  };
}
