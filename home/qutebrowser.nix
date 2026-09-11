_: {
  programs.qutebrowser = {
    enable = true;
    searchEngines.DEFAULT = "https://search.daze.lol/search?q={}";
    settings = {
      content = {
        cookies.accept = "no-3rdparty";
        geolocation = false;
        headers.do_not_track = true;
        webrtc_ip_handling_policy = "default-public-interface-only";
      };
      url = {
        default_page = "https://search.daze.lol/";
        start_pages = ["https://search.daze.lol/"];
      };
      window.hide_decoration = true;
    };
  };
}
