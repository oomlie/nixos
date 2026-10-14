# Media stack. Movies+music and TV are kept on separate physical disks,
# with each library and its download staging on the same filesystem so
# hardlinks/instant moves work. All services share the `media` group and
# run with umask 0002 so files are group-writable.
{
  lib,
  myceliumAddresses,
  pkgs,
  ...
}: {
  users.groups.media = {};

  # setgid (2775) so new files inherit the media group. Owned by root
  # with the media group so every service in the group can read/write.
  systemd.tmpfiles.rules = [
    # Keep /srv traversable by the media group. FileBrowser's module rule for
    # its root (0700 filebrowser:media) is overridden in configuration.nix.
    "z /srv 2775 root media -"
    "d /srv/movies/media 2775 root media -"
    "d /srv/movies/media/movies 2775 root media -"
    "d /srv/movies/media/music 2775 root media -"
    "d /srv/movies/torrents 2775 root media -"
    "d /srv/movies/torrents/movies 2775 root media -"
    "d /srv/movies/torrents/music 2775 root media -"
    "d /srv/movies/usenet 2775 root media -"
    "d /srv/movies/usenet/complete 2775 root media -"
    "d /srv/movies/usenet/complete/movies 2775 root media -"
    "d /srv/movies/usenet/complete/music 2775 root media -"
    "d /srv/tv/media 2775 root media -"
    "d /srv/tv/media/tv 2775 root media -"
    "d /srv/tv/torrents 2775 root media -"
    "d /srv/tv/torrents/tv 2775 root media -"
    "d /srv/tv/usenet 2775 root media -"
    "d /srv/tv/usenet/complete 2775 root media -"
    "d /srv/tv/usenet/complete/tv 2775 root media -"
  ];

  # Web UIs stay closed in the firewall; reach them over SSH/Mycelium.
  services = {
    sonarr = {
      enable = true;
      group = "media";
    };
    radarr = {
      enable = true;
      group = "media";
    };
    lidarr = {
      enable = true;
      group = "media";
    };
    prowlarr.enable = true;
    bazarr = {
      enable = true;
      group = "media";
    };
    jellyfin = {
      enable = true;
      group = "media";
      forceEncodingConfig = true;
      hardwareAcceleration = {
        enable = true;
        type = "nvenc";
        device = "/dev/nvidia0";
      };
    };
    seerr.enable = true;
    navidrome = {
      enable = true;
      group = "media";
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        MusicFolder = "/srv/music";
        EnableInsightsCollector = false;
        EnableUserEditing = false;
        # music.daze.lol is guarded by oauth2-proxy (ratlogin) on halo, but
        # Navidrome didn't trust its identity, so users hit a second Navidrome
        # login. Trust only the halo Mycelium address and sign the user in
        # from the header oauth2-proxy sets with --pass-user-headers.
        ReverseProxyUserHeader = "X-Forwarded-User";
        ReverseProxyWhitelist = "${myceliumAddresses.halo}/128";
      };
    };
    qbittorrent = {
      enable = true;
      group = "media";
      # WebUI credentials, consumed by the *arr download clients. The PBKDF2
      # value is derived from the password in sops (`qbittorrent/webui-password`).
      serverConfig.Preferences.WebUI = {
        Username = "admin";
        Password_PBKDF2 = "@ByteArray(ihVUySZ4c4D+iVSNBl5rpg==:RBGgk5FfDf5tobmzVIbkAZBDMmIHUCdTo2ag9X2upwRVAq91TTO2Qqr4Mcfj/dVZ3DoeMYCeD7mB2ljDn/JS7g==)";
      };
      # Global seeding limit for private-tracker ratio management: seed to
      # ratio 2.0 then pause. Must live here, not the WebUI — the service
      # reinstalls this config on every start.
      serverConfig.BitTorrent = {
        MaxRatioAction = 0;
        Session.GlobalMaxRatio = 2;
        Session.UseCategoryPathsInManualMode = true;
      };
    };
  };

  # Local media UIs on the LAN (behind the router, no port forwards).
  networking.firewall.allowedTCPPorts = [4533 8096];
  networking.firewall.interfaces.mycelium.allowedTCPPorts = [5055 8096];

  # Jellyfin listens on IPv4 only; expose the same port on misty's stable
  # Mycelium IPv6 address for halo's reverse proxy.
  systemd.sockets.jellyfin-mycelium = {
    wantedBy = ["sockets.target"];
    listenStreams = ["[${myceliumAddresses.misty}]:8096"];
    socketConfig = {
      Accept = false;
      FreeBind = true;
    };
  };
  systemd.services =
    lib.recursiveUpdate
    (lib.genAttrs
      ["sonarr" "radarr" "lidarr" "prowlarr" "bazarr" "jellyfin" "qbittorrent"]
      (_: {serviceConfig.UMask = lib.mkForce "0002";}))
    {
      # Jellyfin needs the NVIDIA device nodes for NVENC.
      jellyfin.serviceConfig.DeviceAllow = [
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
      jellyfin-mycelium = {
        requires = ["jellyfin.service"];
        after = ["jellyfin.service"];
        serviceConfig.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8096";
      };
    };
  users.users.jellyfin.extraGroups = ["video" "render"];
}
