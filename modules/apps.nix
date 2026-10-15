{config, ...}: {
  # Forgejo (git forge) with OIDC via ratlogin. The OIDC auth source is a DB
  # entry, so it is added once after first boot:
  #   sudo forgejo admin auth add-oauth --name ratlogin --provider openidConnect \
  #     --key forgejo --secret "$(sudo cat /run/secrets/oidc/forgejo)" \
  #     --auto-discover-url https://auth.daze.lol/.well-known/openid-configuration
  services.forgejo = {
    enable = true;
    useWizard = false;
    database = {
      type = "sqlite3";
    };
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.daze.lol";
        ROOT_URL = "https://git.daze.lol/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3001;
        # Port 22 is not reachable through the Cloudflare proxy; clone over HTTPS.
        DISABLE_SSH = true;
      };
      service = {
        DISABLE_REGISTRATION = true;
        # Local sign-up stays off, but a first ratlogin sign-in may create the account, so the
        # forgejo OIDC client can link molly.computer identities without opening public registration.
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        NO_REPLY_ADDRESS = "noreply.daze.lol";
      };
      # On every ratlogin sign-in, take the avatar from the OIDC `picture` claim. ratlogin emits it
      # from the account's Bluesky profile, so the Forgejo picture follows Bluesky at each login.
      oauth2_client = {
        UPDATE_AVATAR = true;
      };
    };
  };

  # Vikunja (tasks) with OIDC via ratlogin.
  services.vikunja = {
    enable = true;
    address = "127.0.0.1";
    port = 3456;
    frontendScheme = "https";
    frontendHostname = "tasks.daze.lol";
    database = {
      type = "sqlite";
      path = "/var/lib/vikunja/vikunja.db";
    };
    environmentFiles = ["/run/vikunja-oidc.env"];
    settings = {
      auth.local.enabled = false;
      auth.openid = {
        enabled = true;
        redirecturl = "https://tasks.daze.lol/auth/openid/ratlogin";
        providers.ratlogin = {
          name = "ratlogin";
          authurl = "https://auth.daze.lol";
          clientid = "vikunja";
          # clientsecret arrives via VIKUNJA_AUTH_OPENID_PROVIDERS_RATLOGIN_CLIENTSECRET
        };
      };
    };
  };

  # SearXNG (private metasearch).
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets."searx-env".path;
    settings = {
      general.instance_name = "daze search";
      search.formats = ["html" "json"];
      server = {
        bind_address = "127.0.0.1";
        port = 3016;
        base_url = "https://search.daze.lol/";
        secret_key = "$SEARX_SECRET_KEY";
        limiter = true;
      };
    };
    redisCreateLocally = true;
    limiterSettings.botdetection = {
      trusted_proxies = ["127.0.0.0/8" "::1"];
      ip_lists.pass_ip = ["127.0.0.0/8" "::1"];
    };
  };

  sops.secrets."searx-env" = {
    sopsFile = ../secrets/halo.yaml;
    owner = "searx";
    group = "searx";
    mode = "0400";
    restartUnits = ["searx.service"];
  };
}
