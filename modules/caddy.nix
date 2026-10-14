{
  pkgs,
  config,
  myceliumAddresses,
  ...
}: let
  # Reverse proxy helper: HTTP/2 + WebSocket support to a loopback backend.
  proxy = host: port: ''
    reverse_proxy ${host}:${toString port} {
      flush_interval -1
    }
  '';
in {
  services.caddy = {
    enable = true;
    # Cloudflare DNS plugin enables the wildcard TLS cert for *.daze.lol
    # (wildcard certs need DNS-01). One-time Go rebuild, no binary cache.
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
      hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
    };
    environmentFile = "/run/caddy-dns.env";
    # Set a real contact address before first ACME issuance.
    # email = "admin@daze.lol";
    # Alternative if Cloudflare proxying is ever wanted: keep these same
    # virtualHosts and let Caddy use HTTP-01; the acme email above plus DNS
    # already pointing at the host is all it needs.
    virtualHosts = {
      "https://daze.lol" = {
        extraConfig = ''
          encode zstd gzip
          tls {
            dns cloudflare {env.CF_DNS_API_TOKEN}
          }
          root * /var/www/tilde
          file_server
        '';
      };
      "https://tilde.daze.lol" = {
        extraConfig = ''
          encode zstd gzip

          # Landing page (static files; see systemd.tmpfiles below).
          root * /var/www/tilde
          file_server

          # Per-user websites: /~<user> -> /home/<user>/public_html
          @userdir path_regexp ^/~(?P<user>[^/]+)(?:/(?P<rest>.*))?$
          handle @userdir {
            root * /home
            rewrite * /{re.user}/public_html/{re.rest}
            file_server
          }
        '';
      };
      # Wildcard per-user domains: <user>.daze.lol -> /home/<user>/public_html.
      # Exact service vhosts in this file take precedence over this wildcard.
      # System usernames without a public_html simply 404.
      "https://*.daze.lol" = {
        extraConfig = ''
          encode zstd gzip
          tls {
            dns cloudflare {env.CF_DNS_API_TOKEN}
          }
          @atproto path /.well-known/atproto-did /.well-known/did.json
          handle @atproto {
            reverse_proxy 127.0.0.1:3000 {
              header_up Host {http.request.host}
            }
          }
          root * /home/{labels.0}/public_html
          file_server
        '';
      };
      "https://auth.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 9411;
      };
      "https://code.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 3001;
      };
      "https://tasks.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 3456;
      };
      "https://search.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 3016;
      };
      "https://pds.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 3000;
      };
      "https://pds-admin.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 4181;
      };
      "https://knot.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 5555;
      };
      "https://spindle.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 6555;
      };
      "https://hold.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 8091;
      };
      # niri (Mica) web UI, behind the ratlogin guard on 4188.
      "https://niri.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 4188;
      };
      "https://cdn.daze.lol" = {
        # Hold blob downloads are served by Garage's S3 API.
        extraConfig = proxy "127.0.0.1" 3900;
      };
      "https://route.daze.lol" = {
        extraConfig = ''
          # Zeta 2.1 adapter for LSP-AI/Helix: rewrites FIM prompts into Zeta's
          # Multi-Region format. Auth is enforced by the adapter.
          handle_path /zeta-lsp/* {
            reverse_proxy 127.0.0.1:8098 {
              flush_interval -1
            }
          }
          # Zeta 2.1 edit-prediction model (llama.cpp). The API key is enforced
          # by llama-server, not here.
          handle_path /zeta/* {
            reverse_proxy 127.0.0.1:8097 {
              flush_interval -1
            }
          }
          # Management UI, behind the ratlogin guard on 4193. The panel is a
          # single-file hash-routed SPA, so /ui is a plain alias: rewrite it to
          # the bundled panel and let the fragment carry the client-side route.
          handle /management.html {
            reverse_proxy 127.0.0.1:4193
          }
          handle /ui {
            rewrite * /management.html
            reverse_proxy 127.0.0.1:4193
          }
          handle_path /ui/* {
            rewrite * /management.html
            reverse_proxy 127.0.0.1:4193
          }
          handle /oauth2/* {
            reverse_proxy 127.0.0.1:4193
          }
          handle {
            reverse_proxy 127.0.0.1:8317 {
              flush_interval -1
            }
          }
        '';
      };
      "https://requests.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 4183;
      };
      "https://chat.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 8082;
      };
      "https://dash.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 4185;
      };
      "https://game.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 8093;
      };
      # Invidious (OIDC fork) runs on misty; halo is the public edge. Reach it
      # over Mycelium (misty is on a different LAN than halo).
      "https://yt.daze.lol" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy [${myceliumAddresses.misty}]:3000 {
            header_up Host {http.request.host}
            header_up X-Forwarded-Proto {http.request.scheme}
            header_up X-Forwarded-For {http.request.remote}
            flush_interval -1
          }
        '';
      };
      # Jellyfin on misty; login is handled in-app by the SSO plugin (ratlogin),
      # so there is no oauth2-proxy in front of it.
      "https://video.daze.lol" = {
        extraConfig = proxy "[${myceliumAddresses.misty}]" 8096;
      };
      "https://cloud.daze.lol" = {
        extraConfig = proxy "[${myceliumAddresses.misty}]" 8081;
      };
      "https://music.daze.lol" = {
        extraConfig = ''
          # ponytail: remove after existing tinysub clients fetch this cleanup worker.
          handle /sw.js {
            header Cache-Control "no-store"
            header Content-Type "application/javascript"
            respond <<SW
              self.addEventListener("install", () => self.skipWaiting());
              self.addEventListener("activate", event => event.waitUntil((async () => {
                for (const key of await caches.keys()) await caches.delete(key);
                await self.registration.unregister();
                for (const client of await self.clients.matchAll({ type: "window" })) client.navigate("/");
              })()));
              SW 200
          }
          # Navidrome has no OIDC/avatar support; serve the user's Bluesky
          # picture here instead of its placeholder.
          handle /rest/getAvatar* {
            reverse_proxy 127.0.0.1:4191
          }
          handle {
            ${proxy "127.0.0.1" 4186}
          }
        '';
      };
      "https://seerr.daze.lol" = {
        # Seerr authenticates with Jellyfin (Quick Connect). The login shim
        # adds an explainer banner and hides non-Quick-Connect controls.
        extraConfig = proxy "127.0.0.1" 4192;
      };
      "https://files.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 4190;
      };
      "https://irc.daze.lol" = {
        extraConfig = ''
          encode zstd gzip
          root * ${pkgs.gamja}
          file_server

          # gamja connects to soju over WebSocket.
          @ws path /socket
          handle @ws {
            reverse_proxy 127.0.0.1:8818
          }
        '';
      };
      "https://paste.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 8090;
      };
      "https://rsshub.daze.lol" = {
        extraConfig = proxy "127.0.0.1" 1200;
      };
      "https://planet.daze.lol" = {
        extraConfig = ''
          encode zstd gzip
          root * /var/www/planet
          file_server
        '';
      };
      "https://scryphil.daze.lol" = {
        extraConfig = ''
          encode zstd gzip
          root * /var/www/scryphil
          file_server
        '';
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/www/tilde 0755 root root - -"
    "L+ /var/www/tilde/index.html - - - - ${./tilde-homepage.html}"
    "d /var/www/tilde/fonts 0755 root root - -"
    "L+ /var/www/tilde/fonts/ComicMono.woff2 - - - - ${../static/fonts/ComicMono.woff2}"
    "L+ /var/www/tilde/fonts/ComicMono-Bold.woff2 - - - - ${../static/fonts/ComicMono-Bold.woff2}"
    "d /var/www/scryphil 0755 root root - -"
    "L+ /var/www/scryphil/index.html - - - - ${../static/scryphil/index.html}"
    "L+ /var/www/scryphil/glfx.js - - - - ${../static/scryphil/glfx.js}"
    "L+ /var/www/scryphil/phil.png - - - - ${../static/scryphil/phil.png}"
    "L+ /var/www/scryphil/thumb2.png - - - - ${../static/scryphil/thumb2.png}"
  ];

  # Expose the Cloudflare API token to caddy as CF_DNS_API_TOKEN for the
  # *.daze.lol wildcard cert. systemd reads the file as root (PID1).
  systemd.services.caddy-dns-env = {
    before = ["caddy.service"];
    requiredBy = ["caddy.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'CF_DNS_API_TOKEN=%s\n' "$(cat ${config.sops.secrets."acme/cloudflare".path})" >/run/caddy-dns.env
    '';
  };
}
