// Bluesky avatar shim for Navidrome.
//
// Navidrome 0.64 has no OIDC and no avatar upload; its /rest/getAvatar
// endpoint serves a placeholder. music.daze.lol (Caddy on halo) routes that
// path here instead. The Navidrome username is the ATProto DID (set by the
// ratlogin reverse-proxy), which the public AppView resolves directly.
//
// On a hit we stream the picture; on a miss (or any error) we proxy the
// original request through to Navidrome so the normal placeholder is shown.

import http from "node:http";

const port = Number(process.env.PORT ?? 4191);
const navidrome = new URL(process.env.NAVIDROME ?? "http://127.0.0.1:4533");
const appview = "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile";
const userAgent = "daze-nav-avatar/1.0 (+https://daze.lol)";
const okTtl = 10 * 60 * 1000;
const missTtl = 60 * 1000;
const cache = new Map();

async function resolveAvatar(actor) {
  const hit = cache.get(actor);
  if (hit && hit.expires > Date.now()) return hit.url;

  let url = null;
  try {
    const endpoint = new URL(appview);
    endpoint.searchParams.set("actor", actor);
    const response = await fetch(endpoint, {
      headers: { "user-agent": userAgent },
      signal: AbortSignal.timeout(5000),
      redirect: "follow",
    });
    if (response.ok) {
      const profile = await response.json();
      if (typeof profile?.avatar === "string" && profile.avatar.startsWith("https://")) {
        url = profile.avatar;
      }
    }
  } catch {}

  cache.set(actor, { url, expires: Date.now() + (url ? okTtl : missTtl) });
  return url;
}

function fallback(request, response) {
  const upstream = http.request(
    {
      hostname: navidrome.hostname,
      port: navidrome.port || 80,
      method: request.method,
      path: request.url,
      headers: { ...request.headers, host: navidrome.host },
    },
    (upstreamResponse) => {
      response.writeHead(upstreamResponse.statusCode ?? 502, upstreamResponse.headers);
      upstreamResponse.pipe(response);
    },
  );
  upstream.on("error", () => {
    response.writeHead(502);
    response.end();
  });
  request.pipe(upstream);
}

const server = http.createServer(async (request, response) => {
  try {
    const url = new URL(request.url, "http://localhost");
    if (url.pathname.startsWith("/rest/getAvatar")) {
      const actor = url.searchParams.get("username");
      const avatar = actor ? await resolveAvatar(actor) : null;
      if (avatar) {
        const image = await fetch(avatar, {
          headers: { "user-agent": userAgent },
          signal: AbortSignal.timeout(5000),
        });
        if (image.ok) {
          const body = Buffer.from(await image.arrayBuffer());
          response.writeHead(200, {
            "content-type": image.headers.get("content-type") ?? "image/jpeg",
            "cache-control": "public, max-age=3600",
            "content-length": String(body.length),
          });
          response.end(body);
          return;
        }
      }
    }
  } catch {}
  fallback(request, response);
});

server.listen(port, "127.0.0.1");
