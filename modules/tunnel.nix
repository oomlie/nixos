{config, ...}: {
  # Cloudflare Tunnel: keep outbound-only ingress so halo stays reachable from
  # behind NAT and a dynamic residential IP. All HTTP routes point at Caddy,
  # which terminates TLS (wildcard DNS-01 cert) and reverse-proxies each vhost.
  services.cloudflared = {
    enable = true;
    tunnels."halo-llama" = {
      credentialsFile = config.sops.secrets."cloudflare/tunnel-credentials".path;
      default = "http_status:404";
      # Outbound QUIC/UDP 7844 is blocked on this network, so "auto" keeps
      # retrying QUIC and the tunnel fails to (re)connect; force HTTP/2 over TCP.
      protocol = "http2";
      ingress = {
        "daze.lol" = {
          service = "https://localhost:443";
          originRequest.noTLSVerify = true;
        };
        "*.daze.lol" = {
          service = "https://localhost:443";
          originRequest.noTLSVerify = true;
        };
      };
    };
  };

  sops.secrets."cloudflare/tunnel-credentials" = {
    sopsFile = ../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["cloudflared-tunnel-halo-llama.service"];
  };
}
