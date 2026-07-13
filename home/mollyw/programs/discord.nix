{pkgs, ...}: {
  programs.discord = {
    enable = true;
    package = pkgs.discord.override {
      withOpenASAR = true; # rewritten app.asar: faster startup, less telemetry
      withMoonlight = true; # moonlight client mod (extension ecosystem)
    };
    settings = {
      # nix owns the binary; stop self-update nagging
      SKIP_HOST_UPDATE = true;
    };
  };
}
