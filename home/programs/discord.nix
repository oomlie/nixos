{pkgs, ...}: {
  # Moonlight is a from-scratch Discord client mod (themes/plugins configured
  # in-app, in Discord's own settings.json — nothing further to declare here).
  programs.discord = {
    enable = true;
    package = pkgs.discord.override {
      withMoonlight = true;
    };
    settings.SKIP_HOST_UPDATE = true;
  };
}
