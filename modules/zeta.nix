{
  config,
  pkgs,
  zetaAdapter,
  ...
}: let
  # Zeta 2.1 Q8_0 (8B edit-prediction model) served by llama.cpp. Heavy quants
  # degrade it, so Q8_0 is the smallest usable size (~8.5G).
  gguf = pkgs.fetchurl {
    url = "https://huggingface.co/mradermacher/zeta-2.1-GGUF/resolve/main/zeta-2.1.Q8_0.gguf";
    hash = "sha256-KTfKSy7DtKTqdKpJ+jXt4bY0Tv+aZ4Vfek9LqrJXG6Y=";
  };
in {
  users.users.zeta = {
    isSystemUser = true;
    group = "zeta";
  };
  users.groups.zeta = {};

  systemd.services.zeta-llama = {
    description = "llama.cpp server for Zeta 2.1 edit prediction";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "zeta";
      Group = "zeta";
      # Vulkan needs the GPU device nodes.
      SupplementaryGroups = ["video" "render"];
      EnvironmentFile = "/run/zeta.env";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server ${
        pkgs.lib.escapeShellArgs [
          "--model"
          "${gguf}"
          "--host"
          "127.0.0.1"
          "--port"
          "8097"
          "--alias"
          "zeta2.1"
          "--ctx-size"
          "16384"
          "--n-gpu-layers"
          "999"
          "--flash-attn"
          "auto"
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

  # Bridges LSP-AI (Helix) FIM requests into Zeta's Multi-Region prompt format.
  systemd.services.zeta-adapter = {
    description = "Zeta 2.1 prompt adapter for LSP-AI";
    after = ["zeta-llama.service"];
    wants = ["zeta-llama.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "zeta";
      Group = "zeta";
      EnvironmentFile = "/run/zeta.env";
      Environment = [
        "ZETA_ADAPTER_HOST=127.0.0.1"
        "ZETA_ADAPTER_PORT=8098"
        "ZETA_UPSTREAM=http://127.0.0.1:8097/v1/completions"
      ];
      ExecStart = "${zetaAdapter}/bin/zeta-adapter";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictSUIDSGID = true;
    };
  };

  systemd.services.zeta-env = {
    before = ["zeta-llama.service"];
    requiredBy = ["zeta-llama.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'LLAMA_API_KEY=%s\n' "$(cat ${config.sops.secrets."route/api-key".path})" >/run/zeta.env
    '';
  };

  sops.secrets."route/api-key".restartUnits = [
    "zeta-env.service"
    "zeta-llama.service"
  ];
}
