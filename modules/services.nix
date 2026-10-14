_: {
  # Microbin: pastebin + file host. Anonymous pasting is allowed; abuse
  # control lives on Cloudflare in front of Caddy.
  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = "8090";
      MICROBIN_PUBLIC_PATH = "https://paste.daze.lol";
      MICROBIN_HIDE_FOOTER = true;
    };
  };

  # RSSHub: public feed generator.
  services.rsshub = {
    enable = true;
    settings = {
      PORT = 1200;
      LISTEN_INADDR_ANY = false;
    };
  };
}
