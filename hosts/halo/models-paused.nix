{lib, ...}: {
  # TEMPORARY: pause halo's local model inference for the repo consolidation.
  # Remove the units entirely so routine system builds do not fetch their GGUF
  # closures. Remove this import to resume model hosting.
  systemd.services.qwen-llama = lib.mkForce {};
  systemd.services.qwen3-llama = lib.mkForce {};
  systemd.services.zeta-llama = lib.mkForce {};
  systemd.services.zeta-adapter = lib.mkForce {};
  systemd.services.qwen-igpu-clocks = lib.mkForce {};
}
