_: {
  programs.qutebrowser = {
    enable = true;

    aliases = {
      wq = "quit --save";
      qa = "quit --save";
    };

    searchEngines = {
      DEFAULT = "https://search.daze.lol/search?q={}";
      np = "https://search.nixos.org/packages?query={}";
      nw = "https://wiki.nixos.org/w/index.php?search={}";
    };

    keyMappings = {
      "<Ctrl+[>" = "<Escape>";
    };

    settings = {
      content = {
        cookies.accept = "no-3rdparty";
        geolocation = false;
        headers.do_not_track = true;
        webrtc_ip_handling_policy = "default-public-interface-only";
        blocking = {
          enabled = true;
          method = "both";
          adblock.lists = [
            "https://easylist.to/easylist/easylist.txt"
            "https://easylist.to/easylist/easyprivacy.txt"
          ];
        };
      };
      downloads.location = {
        directory = "~/Downloads";
        prompt = false;
      };
      editor.command = ["footclient" "-e" "hx" "{file}"];
      url = {
        default_page = "https://search.daze.lol/";
        start_pages = ["https://search.daze.lol/"];
      };
      window.hide_decoration = true;
    };
  };
}
