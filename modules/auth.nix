{
  config,
  inputs,
  pkgs,
  ...
}: {
  services.ratlogin = {
    enable = true;
    # ponytail: Vikunja 2.6 sends state but neither PKCE nor nonce; keep the
    # compatibility exception scoped to this confidential client.
    package = inputs.ratlogin.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or []) ++ [../patches/ratlogin-local.patch];
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace src/oidc.rs \
            --replace-fail \
              'if challenge.is_none() && nonce.is_none() {' \
              'if challenge.is_none() && nonce.is_none() && client_id.as_str() != "vikunja" {'
          substituteInPlace src/web/session.rs \
            --replace-fail \
              'fresh && hinted' \
              'fresh && hinted && (!request.client.email_policy().discloses() || session.email.is_some())'
        '';
    });
    issuer = "https://auth.daze.lol";
    clientName = "daze";
    clients = [
      {
        id = "forgejo";
        redirectUris = ["https://code.daze.lol/user/oauth2/ratlogin/callback"];
        secretFile = config.sops.secrets."oidc/forgejo".path;
        group = "forgejo";
      }
      {
        id = "vikunja";
        redirectUris = ["https://tasks.daze.lol/auth/openid/ratlogin"];
        secretFile = config.sops.secrets."oidc/vikunja".path;
        email = "required";
      }
      {
        id = "romm";
        redirectUris = ["https://game.daze.lol/api/oauth/openid"];
        secretFile = config.sops.secrets."oidc/romm".path;
        email = "required";
      }
      {
        id = "invidious";
        redirectUris = ["https://yt.daze.lol/oidc/callback"];
        secretFile = config.sops.secrets."oidc/invidious".path;
        email = "required";
      }
      {
        # Jellyfin native SSO (K0lin/jellyfin-plugin-sso). The plugin uses the
        # /sso/OID/redirect/<provider> callback.
        id = "jellyfin";
        redirectUris = ["https://video.daze.lol/sso/OID/redirect/ratlogin"];
        secretFile = config.sops.secrets."oidc/jellyfin".path;
        email = "required";
      }
    ];
  };

  # Sign-in is limited to molly.computer and its Bluesky mutual follows. The
  # patched ratlogin binary reads this; the option cannot live in the module
  # because only the package is patched, not the flake input.
  systemd.services.ratlogin.environment.RATLOGIN_MUTUALS_OF = "molly.computer";

  # OIDC client secrets are generated once and stored in SOPS, then shared
  # between ratlogin and the consuming services. Add them with:
  #   sops secrets/halo.yaml
  #
  # Alternative: drop the `secretFile` fields below and let ratlogin generate
  # per-client secrets under /etc/ratlogin/clients (chowned to each service
  # group). Consuming apps then read those files instead of sops paths.
  sops.secrets."oidc/forgejo" = {
    sopsFile = ../secrets/halo.yaml;
    group = "forgejo";
    mode = "0440";
    restartUnits = ["ratlogin.service"];
  };
  sops.secrets."oidc/vikunja" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["ratlogin.service"];
  };
  sops.secrets."oidc/romm" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["ratlogin.service"];
  };
  # Shared with misty (the Invidious instance reads the same client secret).
  sops.secrets."oidc/invidious" = {
    sopsFile = ../secrets/misty.yaml;
    mode = "0400";
    restartUnits = ["ratlogin.service"];
  };
  # Shared with misty (the Jellyfin SSO plugin reads the same client secret).
  sops.secrets."oidc/jellyfin" = {
    sopsFile = ../secrets/misty.yaml;
    mode = "0400";
    restartUnits = ["ratlogin.service"];
  };

  # Vikunja runs under a DynamicUser, so systemd reads this root-owned env file
  # (as PID1) and passes the client secret through an environment variable.
  systemd.services.vikunja-oidc-env = {
    before = ["vikunja.service"];
    requiredBy = ["vikunja.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'VIKUNJA_AUTH_OPENID_PROVIDERS_RATLOGIN_CLIENTSECRET=%s\n' \
        "$(cat ${config.sops.secrets."oidc/vikunja".path})" >/run/vikunja-oidc.env
    '';
  };
}
