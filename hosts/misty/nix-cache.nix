# Serve misty's Nix store as a signed binary cache over Mycelium, so
# anything built on misty (e.g. by the remote builder on chi) is reusable by
# the other hosts instead of being rebuilt or re-downloaded.
{config, ...}: {
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [config.sops.secrets."nix-cache/signing-key".path];
  };

  sops.secrets."nix-cache/signing-key" = {
    sopsFile = ../../secrets/misty.yaml;
  };

  # The cache binds [::]:5000; only Mycelium may reach it. Clients trust the
  # `misty-cache-1` public key, so untrusted cache content is rejected.
  networking.firewall.interfaces.mycelium.allowedTCPPorts = [5000];
}
