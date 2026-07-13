{
  inputs,
  pkgs,
  ...
}: {
  programs.firefox = {
    enable = true;
    profiles.mollyw = {
      id = 0;
      isDefault = true;
      settings = {
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "extensions.pocket.enabled" = false;
        "browser.toolbars.bookmarks.visibility" = "always";
      };
      extensions.packages = [
        inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}.ublock-origin
      ];
    };
  };
}
