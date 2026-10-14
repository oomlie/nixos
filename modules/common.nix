{
  lib,
  myceliumAddresses,
  ...
}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    # 256 MiB download buffer: fewer stalls on large fetches.
    download-buffer-size = 268435456;
    # misty serves a signed binary cache over Mycelium (see
    # hosts/misty/nix-cache.nix); reuse its store before rebuilding.
    extra-substituters = ["http://[${myceliumAddresses.misty}]:5000"];
    extra-trusted-public-keys = ["misty-cache-1:skiBr7GfZnuoVq6uMBDjR1HtqSfBAb/6rFNFm3K3mxQ="];
    # Best-effort: if misty (or any substituter) is unreachable, fall back to
    # building locally instead of aborting. Nix disables the failing cache for
    # 60s after the first error, so a mesh outage only costs one retry.
    fallback = true;
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.firewall.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.defaultPackages = lib.mkForce [];

  system.stateVersion = "26.05";
}
