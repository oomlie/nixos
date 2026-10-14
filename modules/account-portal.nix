{
  accountPortal,
  config,
  lib,
  myceliumAddresses,
  pkgs,
  tildeProvision,
  ...
}: let
  proxyExe = lib.getExe pkgs.oauth2-proxy;
  clientSecret = config.sops.secrets."oidc/oauth2-proxy".path;
  cookieSecret = config.sops.secrets."oauth2-proxy/cookie-secret".path;
  dazeLogo = ../static/daze-logo.svg;
  mkProxy = {
    name,
    port,
    host,
    upstream,
    environmentFile ? null,
    clientId ? "oauth2-proxy",
    skipProviderButton ? true,
  }: {
    description = "ratlogin guard for ${host}";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      {
        User = "oauth2-proxy";
        Group = "oauth2-proxy";
        ExecStart = lib.escapeShellArgs (
          [
            proxyExe
            "--provider=oidc"
            "--provider-display-name=ratlogin"
            "--oidc-issuer-url=https://auth.daze.lol"
            "--client-id=${clientId}"
            "--client-secret-file=${clientSecret}"
            "--cookie-secret-file=${cookieSecret}"
            "--cookie-name=_oauth2_${name}"
            "--redirect-url=https://${host}/oauth2/callback"
            "--http-address=127.0.0.1:${toString port}"
            "--upstream=http://${upstream}"
            "--email-domain=*"
            "--oidc-email-claim=sub"
            "--insecure-oidc-allow-unverified-email=true"
            "--scope=openid profile"
            "--code-challenge-method=S256"
            "--cookie-secure=true"
            "--cookie-samesite=lax"
            "--session-cookie-minimal=true"
            "--pass-user-headers=true"
            "--pass-basic-auth=true"
            "--reverse-proxy=true"
            "--trusted-proxy-ip=127.0.0.1/32"
            "--whitelist-domain=.daze.lol"
            "--custom-sign-in-logo=${dazeLogo}"
            "--footer=daze.lol — a pubnix"
          ]
          ++ lib.optional skipProviderButton "--skip-provider-button=true"
        );
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
      }
      // lib.optionalAttrs (environmentFile != null) {
        EnvironmentFile = environmentFile;
      };
  };
in {
  users.users.oauth2-proxy = {
    isSystemUser = true;
    group = "oauth2-proxy";
  };
  users.groups.oauth2-proxy = {};

  users.users.tilde-requests = {
    isSystemUser = true;
    group = "tilde-requests";
  };
  users.groups.tilde-requests = {};

  services.ratlogin.clients = [
    {
      id = "oauth2-proxy";
      secretFile = clientSecret;
      group = "oauth2-proxy";
      redirectUris = [
        "https://pds-admin.daze.lol/oauth2/callback"
        "https://requests.daze.lol/oauth2/callback"
        "https://dash.daze.lol/oauth2/callback"
        "https://music.daze.lol/oauth2/callback"
        "https://niri.daze.lol/oauth2/callback"
        "https://files.daze.lol/oauth2/callback"
      ];
    }
    {
      id = "open-webui";
      secretFile = clientSecret;
      group = "oauth2-proxy";
      redirectUris = ["https://chat.daze.lol/oauth/oidc/login/callback"];
    }
  ];

  sops.secrets."oidc/oauth2-proxy" = {
    sopsFile = ../secrets/halo.yaml;
    group = "oauth2-proxy";
    mode = "0440";
    restartUnits = [
      "ratlogin.service"
      "oauth2-proxy-pds-admin.service"
      "oauth2-proxy-requests.service"
      "oauth2-proxy-dashboard.service"
      "oauth2-proxy-music.service"
      "oauth2-proxy-files.service"
      "oauth2-proxy-niri.service"
      "open-webui.service"
    ];
  };
  sops.secrets."oauth2-proxy/cookie-secret" = {
    sopsFile = ../secrets/halo.yaml;
    group = "oauth2-proxy";
    mode = "0440";
    restartUnits = [
      "oauth2-proxy-pds-admin.service"
      "oauth2-proxy-requests.service"
      "oauth2-proxy-dashboard.service"
      "oauth2-proxy-music.service"
      "oauth2-proxy-files.service"
      "oauth2-proxy-niri.service"
      "open-webui.service"
    ];
  };

  sops.secrets."oauth2-proxy/backend-secret" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = [
      "oauth2-proxy-requests.service"
      "tilde-requests.service"
    ];
  };
  # Cloudflare Email Routing credentials for per-user forwarding at approval.
  # Value is a multi-line KEY=VALUE environment file.
  sops.secrets."cloudflare/email-routing" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
  };

  systemd.services.tilde-requests-proxy-env = {
    before = [
      "oauth2-proxy-requests.service"
      "tilde-requests.service"
    ];
    requiredBy = [
      "oauth2-proxy-requests.service"
      "tilde-requests.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      secret="$(cat ${config.sops.secrets."oauth2-proxy/backend-secret".path})"
      {
        printf 'OAUTH2_PROXY_BASIC_AUTH_PASSWORD=%s\n' "$secret"
        printf 'TILDE_REQUEST_PROXY_SECRET=%s\n' "$secret"
      } >/run/tilde-requests-proxy.env
    '';
  };
  systemd.services.oauth2-proxy-pds-admin = mkProxy {
    name = "pds_admin";
    port = 4181;
    host = "pds-admin.daze.lol";
    upstream = "127.0.0.1:8787";
  };

  systemd.services.oauth2-proxy-requests = mkProxy {
    name = "requests";
    port = 4183;
    host = "requests.daze.lol";
    upstream = "127.0.0.1:8092";
    environmentFile = "/run/tilde-requests-proxy.env";
  };

  systemd.services.oauth2-proxy-dashboard = mkProxy {
    name = "dashboard";
    port = 4185;
    host = "dash.daze.lol";
    upstream = "127.0.0.1:8096";
  };

  systemd.services.oauth2-proxy-music = mkProxy {
    name = "music";
    port = 4186;
    host = "music.daze.lol";
    upstream = "[${myceliumAddresses.misty}]:4533";
  };

  # niri (Mica) web UI. The container publishes only on loopback (3004);
  # Mica's memory file asks for no public exposure without a guard.
  systemd.services.oauth2-proxy-niri = mkProxy {
    name = "niri";
    port = 4188;
    host = "niri.daze.lol";
    upstream = "127.0.0.1:3004";
  };

  # Media stack on misty, reached over Mycelium.
  systemd.services.oauth2-proxy-files = mkProxy {
    name = "files";
    port = 4190;
    host = "files.daze.lol";
    upstream = "[${myceliumAddresses.misty}]:8088";
  };

  systemd.services.tilde-requests = {
    description = "daze.lol account request portal";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "tilde-requests";
      Group = "tilde-requests";
      ExecStart = "${accountPortal}/bin/tilde-requests serve --port 8092";
      EnvironmentFile = "/run/tilde-requests-proxy.env";
      StateDirectory = "tilde-requests";
      StateDirectoryMode = "2770";
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
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
    };
  };

  environment.systemPackages = [
    accountPortal
    (pkgs.writeShellApplication {
      name = "tilde-requests-approve";
      runtimeInputs = [accountPortal tildeProvision];
      text = ''
        exec tilde-requests approve \
          --email-command ${tildeProvision}/bin/tilde-provision \
          --email-env-file ${config.sops.secrets."cloudflare/email-routing".path} \
          "$@"
      '';
    })
  ];
}
