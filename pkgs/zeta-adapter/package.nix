{writers, ...}:
# Zeta 2.1 prompt adapter (stdlib only). See zeta_adapter.py.
writers.writePython3Bin "zeta-adapter" {
  libraries = [];
  flakeIgnore = ["E501" "W503" "E203" "E265"];
} (builtins.readFile ./zeta_adapter.py)
