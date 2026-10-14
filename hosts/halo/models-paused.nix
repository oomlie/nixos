{lib, ...}: {
  # Opt-in override that pauses halo's local model inference by removing the
  # units entirely, so routine system builds do not fetch their GGUF closures.
  # Not imported by default; add it to hosts/halo/configuration.nix when you
  # need to build or deploy halo without the model closures.
  systemd.services.qwen-llama = lib.mkForce {};
  systemd.services.qwen3-llama = lib.mkForce {};
  systemd.services.zeta-llama = lib.mkForce {};
  systemd.services.zeta-adapter = lib.mkForce {};
  systemd.services.qwen-igpu-clocks = lib.mkForce {};
}
