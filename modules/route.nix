{
  config,
  openrouterZdrProxy,
  pkgs,
  ...
}: {
  # CLIProxyAPI ("route"): OpenAI/Claude/Codex-compatible gateway. Pinned by
  # digest; state (config.yaml, auths, plugins) lives on the host.
  # Alternative: build the fork from source with buildGoModule
  # (github:router-for-me/CLIProxyAPI) when the `purplish` build needs local
  # patches instead of the upstream image.
  virtualisation.oci-containers.containers.cli-proxy-api = {
    image = "docker.io/eceasy/cli-proxy-api@sha256:cba3af35ed147ffca3ac10bc5a743d4369ce5e4e9b59c86ff9d980d51323875d";
    ports = [
      "127.0.0.1:8317:8317"
      "127.0.0.1:1455:1455"
      "127.0.0.1:54545:54545"
      "127.0.0.1:51121:51121"
    ];
    volumes = [
      "/var/lib/cliproxyapi/config.yaml:/CLIProxyAPI/config.yaml"
      "/var/lib/cliproxyapi/auths:/root/.cli-proxy-api"
      "/var/lib/cliproxyapi/plugins:/CLIProxyAPI/plugins"
    ];
    autoStart = true;
  };

  systemd.services.cli-proxy-api-key = {
    before = ["podman-cli-proxy-api.service"];
    requiredBy = ["podman-cli-proxy-api.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      config=/var/lib/cliproxyapi/config.yaml
      for secret in \
        ${config.sops.secrets."route/api-key".path} \
        ${config.sops.secrets."route/alys-api-key".path}; do
        key="$(cat "$secret")"
        if ! ${pkgs.gnugrep}/bin/grep -Fqx "  - $key" "$config"; then
          tmp="$config.tmp"
          ${pkgs.gawk}/bin/awk -v key="$key" '
            $0 == "api-keys:" {print; print "  - " key; next}
            {print}
          ' "$config" >"$tmp"
          ${pkgs.coreutils}/bin/install -m 0600 "$tmp" "$config"
          ${pkgs.coreutils}/bin/rm "$tmp"
        fi
      done
    '';
  };

  users.users.openrouter-zdr = {
    isSystemUser = true;
    group = "openrouter-zdr";
  };
  users.groups.openrouter-zdr = {};

  # Open WebUI: chat frontend for route plus a ZDR-enforcing OpenRouter proxy.
  systemd.services.open-webui-env = {
    before = [
      "open-webui.service"
      "openrouter-zdr-proxy.service"
    ];
    requiredBy = [
      "open-webui.service"
      "openrouter-zdr-proxy.service"
    ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      umask 077
      route_key="$(cat ${config.sops.secrets."route/api-key".path})"
      openrouter_key="$(cat ${config.sops.secrets."openrouter/api-key".path})"
      proxy_key="$(cat ${config.sops.secrets."openrouter/proxy-key".path})"
      oidc_secret="$(cat ${config.sops.secrets."oidc/oauth2-proxy".path})"
      {
        printf 'OPENAI_API_KEYS=%s;%s\n' "$route_key" "$proxy_key"
        printf 'OAUTH_CLIENT_SECRET=%s\n' "$oidc_secret"
        printf 'OPENAI_API_CONFIGS=%s\n' '{"0":{"prefix_id":"route"},"1":{"prefix_id":"zdr","model_ids":["anthropic/claude-sonnet-4.5","openai/gpt-4o-mini"]}}'
      } >/run/open-webui.env
      {
        printf 'OPENROUTER_API_KEY=%s\n' "$openrouter_key"
        printf 'OPENROUTER_PROXY_KEY=%s\n' "$proxy_key"
      } >/run/openrouter-zdr.env
    '';
  };

  systemd.services.openrouter-zdr-proxy = {
    description = "OpenRouter ZDR enforcement proxy";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "openrouter-zdr";
      Group = "openrouter-zdr";
      ExecStart = "${openrouterZdrProxy}/bin/openrouter-zdr-proxy serve";
      EnvironmentFile = "/run/openrouter-zdr.env";
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

  services.open-webui = {
    enable = true;
    # Vendored 0.11.4 (nixpkgs pins 0.11.3); see pkgs/open-webui/package.nix.
    package = pkgs.callPackage ../pkgs/open-webui/package.nix {};
    host = "127.0.0.1";
    port = 8082;
    stateDir = "/var/lib/open-webui";
    environmentFile = "/run/open-webui.env";
    environment = {
      OPENAI_API_BASE_URLS = "http://127.0.0.1:8317/v1;http://127.0.0.1:8318/v1";
      ENABLE_PERSISTENT_CONFIG = "false";
      ENABLE_OLLAMA_API = "false";
      ENABLE_OPENAI_API = "true";
      ENABLE_WEB_SEARCH = "true";
      WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://127.0.0.1:3016/search";
      WEB_LOADER_ENGINE = "safe_web";
      ENABLE_OAUTH = "true";
      ENABLE_OAUTH_SIGNUP = "true";
      ENABLE_OAUTH_EMAIL_FALLBACK = "true";
      OAUTH_AUTO_REDIRECT = "true";
      OAUTH_CLIENT_ID = "open-webui";
      OPENID_PROVIDER_URL = "https://auth.daze.lol/.well-known/openid-configuration";
      OPENID_REDIRECT_URI = "https://chat.daze.lol/oauth/oidc/login/callback";
      OAUTH_PROVIDER_NAME = "ratlogin";
      OAUTH_SCOPES = "openid profile";
      OAUTH_SUB_CLAIM = "sub";
      OAUTH_USERNAME_CLAIM = "preferred_username";
      DEFAULT_USER_ROLE = "user";
      WEBUI_URL = "https://chat.daze.lol";
      WEBUI_NAME = "daze chat";
    };
  };

  sops.secrets."route/api-key" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = [
      "cli-proxy-api-key.service"
      "open-webui.service"
    ];
  };
  sops.secrets."route/alys-api-key" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["cli-proxy-api-key.service"];
  };
  sops.secrets."openrouter/api-key" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = [
      "openrouter-zdr-proxy.service"
      "niri-agent-config.service"
    ];
  };
  sops.secrets."openrouter/proxy-key" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = [
      "open-webui.service"
      "openrouter-zdr-proxy.service"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/cliproxyapi 0700 root root - -"
    "d /var/lib/cliproxyapi/auths 0700 root root - -"
    "d /var/lib/cliproxyapi/plugins 0700 root root - -"
  ];
}
