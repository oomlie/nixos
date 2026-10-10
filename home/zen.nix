{browserProfile, ...}: {
  programs.zen-browser = {
    enable = true;
    profiles.mollyw = browserProfile;
  };
}
