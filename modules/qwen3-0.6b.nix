{
  config,
  lib,
  pkgs,
  ...
}: let
  # Qwen3-0.6B, Q8_0: a tiny local model exposed through route.daze.lol so
  # OpenCode (and other route clients) can pick it as a cheap/fast option.
  gguf = pkgs.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf";
    hash = "sha256-lGXmOiKt1TVNm7S5npARcEPHEkAHZkkHJZvRbQQ7sDE=";
  };
in {
  users.users.qwen3 = {
    isSystemUser = true;
    group = "qwen3";
  };
  users.groups.qwen3 = {};

  # llama-server reads LLAMA_API_KEY from the environment; reuse the gateway
  # key so the route.daze.lol provider authenticates.
  systemd.services.qwen3-env = {
    before = ["qwen3-llama.service"];
    requiredBy = ["qwen3-llama.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'LLAMA_API_KEY=%s\n' "$(cat ${config.sops.secrets."route/api-key".path})" >/run/qwen3.env
    '';
  };

  systemd.services.qwen3-llama = {
    description = "llama.cpp server for Qwen3-0.6B (Q8_0)";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "qwen3";
      Group = "qwen3";
      # Vulkan needs the GPU device nodes.
      SupplementaryGroups = ["video" "render"];
      EnvironmentFile = "/run/qwen3.env";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server ${
        lib.escapeShellArgs [
          "--model"
          "${gguf}"
          # The CLIProxyAPI container reaches this over the podman bridge
          # gateway, so it cannot bind loopback-only.
          "--host"
          "0.0.0.0"
          "--port"
          "3021"
          "--alias"
          "qwen3-0.6b"
          "--ctx-size"
          "40960"
          "--n-gpu-layers"
          "999"
          "--flash-attn"
          "auto"
          "--jinja"
          "--parallel"
          "1"
          "--no-webui"
        ]
      }";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictSUIDSGID = true;
    };
  };

  # Let the route.daze.lol CLIProxyAPI container dial the model over the podman
  # bridge without exposing 3021 on the LAN.
  networking.firewall.interfaces."podman0".allowedTCPPorts = [3021];

  sops.secrets."route/api-key".restartUnits = [
    "qwen3-env.service"
    "qwen3-llama.service"
  ];
}
