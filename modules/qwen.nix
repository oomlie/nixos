{
  config,
  lib,
  pkgs,
  ...
}: let
  # Qwen3.8-Flash-Next, GSQ-RCO Q2_0: a 512-expert MoE with a vision
  # projector. Shipped as two GGUF shards; shard 2 is a 51.2B per-layer
  # token-embedding lookup table. llama.cpp auto-loads part 2 when part 1 is
  # opened by name, so the shards (and mmproj) are staged in one directory.
  #
  # Q2_0 over IQ3_S: same model, ~2.4 bpw instead of 3.5, and it avoids the
  # lookup-table quant formats whose decode cost dominates. The card measures
  # 93.8 tok/s decode for Q2_0; IQ3_S ran 24-28 tok/s here. Costs ~3.5 points
  # of task-average quality (89.07 vs 89.16 for IQ2_XS). Shard 2 is byte
  # identical across quants, so only shard 1 changes.
  hf = "https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF/resolve/main";
  quant = "Q2_0";
  shard1Name = "Qwen3.8-Flash-Next-GSQ-RCO-Q2_0-00001-of-00002.gguf";
  shard2Name = "Qwen3.8-Flash-Next-GSQ-RCO-Q2_0-00002-of-00002.gguf";
  mmprojName = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
  shard1 = pkgs.fetchurl {
    name = shard1Name;
    url = "${hf}/${quant}/${shard1Name}";
    hash = "sha256-aYIMAux9C0XvLrsZ1mICmdt0n+Kt7X85+TxriLGZtyA=";
  };
  shard2 = pkgs.fetchurl {
    name = shard2Name;
    url = "${hf}/${quant}/${shard2Name}";
    hash = "sha256-MWtG86Lb1oyQD0MTarlEn53MNyXf2MeUhHwgS8Fh4RM=";
  };
  mmproj = pkgs.fetchurl {
    name = mmprojName;
    url = "${hf}/${mmprojName}";
    hash = "sha256-sagiWXAoFqUzDXvXYHzZZ2sReA55/3NIwhED/zzkm9A=";
  };

  modelDir = pkgs.runCommand "qwen3.8-flash-next-q2_0" {} ''
    mkdir -p $out
    ln -s ${shard1} $out/${shard1Name}
    ln -s ${shard2} $out/${shard2Name}
    ln -s ${mmproj} $out/${mmprojName}
  '';
in {
  users.users.qwen = {
    isSystemUser = true;
    group = "qwen";
  };
  users.groups.qwen = {};

  # llama-server reads LLAMA_API_KEY from the environment; reuse the gateway
  # key so the existing route.daze.lol "halo-local" provider authenticates.
  systemd.services.qwen-env = {
    before = ["qwen-llama.service"];
    requiredBy = ["qwen-llama.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      umask 077
      printf 'LLAMA_API_KEY=%s\n' "$(cat ${config.sops.secrets."route/api-key".path})" >/run/qwen.env
    '';
  };

  systemd.services.qwen-llama = {
    description = "llama.cpp server for Qwen3.8-Flash-Next (GSQ-RCO Q2_0)";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "qwen";
      Group = "qwen";
      # Vulkan needs the GPU device nodes.
      SupplementaryGroups = ["video" "render"];
      EnvironmentFile = "/run/qwen.env";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server ${
        lib.escapeShellArgs [
          "--model"
          "${modelDir}/${shard1Name}"
          "--mmproj"
          "${modelDir}/${mmprojName}"
          # The CLIProxyAPI container reaches this over the podman bridge
          # gateway (host.containers.internal -> 10.88.0.1), so it cannot bind
          # loopback-only. The firewall opens 3020 solely on podman0.
          "--host"
          "0.0.0.0"
          "--port"
          "3020"
          "--alias"
          "qwen3.8-flash"
          # 131072: Mica (niri) wakes with ~115k tokens. Ran at this size for
          # hours on 2026-10-04 at 46.8G peak; KV cache cost is acceptable.
          "--ctx-size"
          "131072"
          "--n-gpu-layers"
          "999"
          # Do NOT pin per_layer_token_embd to CPU. GTT is 124 GiB of unified
          # memory, so offloading the 28.8 GiB n-gram table costs no extra RAM
          # but avoids a host->device hop per lookup. Forcing it to CPU made
          # the process swap and dropped decode to ~28 tok/s.
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
      TimeoutStartSec = "600s";
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
  # bridge without exposing 3020 on the LAN.
  networking.firewall.interfaces."podman0".allowedTCPPorts = [3020];

  # nixpkgs has no option for this, so poke sysfs from a oneshot. `manual` pins
  # the iGPU at its max OD clock (2900 MHz) instead of letting amdgpu drop to
  # 600 MHz between bursts, which otherwise adds latency to the first tokens of
  # every request. Host-wide and persistent: it affects every GPU workload,
  # including the desktop compositor. Drop the unit to hand clocks back to
  # `auto`.
  systemd.services.qwen-igpu-clocks = {
    description = "Force the iGPU into its manual performance level for llama.cpp";
    before = ["qwen-llama.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for dev in /sys/class/drm/card*/device; do
        [[ -e "$dev/power_dpm_force_performance_level" ]] || continue
        printf 'manual\n' >"$dev/power_dpm_force_performance_level"
      done
    '';
  };

  sops.secrets."route/api-key".restartUnits = [
    "qwen-env.service"
    "qwen-llama.service"
  ];
}
