// Tiny reverse proxy in front of Seerr that injects a login-page tweak:
// an explainer banner + hiding everything except "Use Quick Connect".
//
// Seerr has no login-message/CSS hooks and builds its login UI client-side,
// so this is a best-effort DOM hack (the user opted in). It only touches
// text/html responses and is a no-op outside the login screen.

import http from "node:http";

const port = Number(process.env.PORT ?? 4192);
const upstream = new URL(process.env.UPSTREAM ?? "http://100.64.0.4:5055");

const clientScript = `
(function(){
  if (window.__dazeQC) return; window.__dazeQC = 1;
  function isLogin(){ return /(^|\\/)login(\\/|$)/.test(location.pathname) || !!document.querySelector('input[type=password]'); }
  function banner(){
    if (!isLogin() || document.getElementById('daze-qc-banner')) return;
    var d = document.createElement('div');
    d.id = 'daze-qc-banner';
    d.style.cssText = 'position:fixed;left:50%;top:16px;transform:translateX(-50%);z-index:9999;width:min(92vw,560px);padding:14px 18px;border-radius:12px;background:#1f2937;color:#e5e7eb;font:14px/1.5 system-ui,-apple-system,sans-serif;box-shadow:0 10px 30px rgba(0,0,0,.45);border:1px solid #374151';
    d.innerHTML = '<b>Sign in with Quick Connect</b><br>' +
      '1. Click <b>Use Quick Connect</b> below.<br>' +
      '2. In Jellyfin (you are already signed in), open your account menu &rarr; Quick Connect and enter the code.<br>' +
      '<span style="opacity:.7">daze.lol uses ratlogin through your Jellyfin account &mdash; there is no password to enter.</span>';
    document.body.appendChild(d);
  }
  function tidy(){
    if (!isLogin()) return;
    document.querySelectorAll('button,a').forEach(function(el){
      var t = (el.textContent || '').toLowerCase();
      if (t.indexOf('plex') >= 0 || t.indexOf('email') >= 0) el.style.display = 'none';
    });
    document.querySelectorAll('button').forEach(function(b){
      if ((b.textContent || '').toLowerCase().indexOf('quick connect') < 0) return;
      var scope = b.closest('form') || b.closest('[role=dialog]') || b.parentElement;
      if (!scope) return;
      scope.querySelectorAll('input').forEach(function(i){ i.style.display = 'none'; });
      scope.querySelectorAll('button').forEach(function(x){ if (x !== b) x.style.display = 'none'; });
    });
  }
  function run(){ try { banner(); tidy(); } catch (e) {} }
  function start(){ run(); new MutationObserver(run).observe(document.body, {childList:true, subtree:true}); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
`;

const injection = `<script data-daze-qc>${clientScript}</script>`;

http
  .createServer((request, response) => {
    const upstreamRequest = http.request(
      {
        hostname: upstream.hostname.replace(/^\[|\]$/g, ""),
        port: upstream.port || 80,
        method: request.method,
        path: request.url,
        headers: {
          ...request.headers,
          host: upstream.host,
          // Uncompressed so we can rewrite; the browser re-negotiates via Caddy.
          "accept-encoding": "identity",
        },
      },
      (upstreamResponse) => {
        const contentType = upstreamResponse.headers["content-type"] ?? "";
        if (!contentType.includes("text/html")) {
          response.writeHead(upstreamResponse.statusCode ?? 502, upstreamResponse.headers);
          upstreamResponse.pipe(response);
          return;
        }

        const chunks = [];
        upstreamResponse.on("data", (chunk) => chunks.push(chunk));
        upstreamResponse.on("end", () => {
          let body = Buffer.concat(chunks).toString("utf8");
          body = body.includes("</body>") ? body.replace("</body>", `${injection}</body>`) : body + injection;
          const headers = {...upstreamResponse.headers};
          delete headers["content-length"];
          delete headers["content-encoding"];
          headers["content-length"] = String(Buffer.byteLength(body));
          response.writeHead(upstreamResponse.statusCode ?? 502, headers);
          response.end(body);
        });
      },
    );
    upstreamRequest.on("error", () => {
      response.writeHead(502);
      response.end();
    });
    request.pipe(upstreamRequest);
  })
  .listen(port, "127.0.0.1");
