{
  config,
  pkgs,
  niri,
  ...
}: let
  niriHome = "/var/lib/niri";

  # Scoped journal access for agents. Each argument must match an allowlisted
  # unit; everything else is refused. Run as `sudo niri-logs <unit> [lines]`
  # or `sudo niri-logs --failed`.
  #
  # Alternative: if agents ever need cross-service tracing, replace the
  # per-unit allowlist with `journalctl` filtering by a systemd `_SYSTEMD_UNIT`
  # glob plus a `--since` cap, still via this same sudoed helper (never grant
  # the niri user membership in `systemd-journal` or unrestricted sudo).
  niri-logs = pkgs.writeShellApplication {
    name = "niri-logs";
    text = ''
      set -euo pipefail

       allowed="niri ratlogin caddy forgejo vikunja searx tranquil-pds knot spindle garage hold podman-hold cli-proxy-api open-webui openrouter-zdr-proxy microbin rsshub tilde-members tilde-planet tilde-user-layout soju i2pd sshd agate geomyidae tilde-requests oauth2-proxy-pds-admin oauth2-proxy-requests pds-operator zeta-llama zeta-adapter qwen-llama"

      if [ "$#" -lt 1 ]; then
        echo "usage: niri-logs <unit> [lines] | niri-logs --failed [lines]" >&2
        exit 2
      fi

      if [ "$1" = "--failed" ]; then
        exec journalctl --no-pager -n "''${2:-100}" --failed
      fi

      unit="$1"
      case " $allowed " in
        *" $unit "*) ;;
        *)
          echo "niri-logs: unit '$unit' is not allowlisted" >&2
          exit 1
          ;;
      esac

      exec journalctl --no-pager -u "$unit" -n "''${2:-100}"
    '';
  };
in {
  users.users.niri = {
    isSystemUser = true;
    group = "niri";
  };
  users.groups.niri = {};

  environment.systemPackages = [niri-logs];

  # Alternative to the embedded tool host: run each agent's `client` against a
  # dedicated microVM/container (see niri's `client: http://host:port` and
  # `client: iroh` modes) so agent shell commands cannot touch the host.
  # The embedded host is a convenience default, not a sandbox.
  systemd.services.niri = {
    description = "niri agent harness";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    preStart = ''
      mkdir -p ${niriHome}/agents
      if [ ! -e ${niriHome}/app/.stamp ] || [ "$(cat ${niriHome}/app/.stamp 2>/dev/null)" != "${niri}" ]; then
        rm -rf ${niriHome}/app
        cp -r ${niri} ${niriHome}/app
        chmod -R u+w ${niriHome}/app
        printf '%s' "${niri}" >${niriHome}/app/.stamp
      fi
    '';
    serviceConfig = {
      Type = "simple";
      User = "niri";
      Group = "niri";
      WorkingDirectory = "${niriHome}/app";
      # `npm run start` = `tsx src/control-plane/index.ts`; --ignore-scripts
      # skips the prestart build (already built at package time).
      # Alternative: exec tsx directly — `${niriHome}/app/node_modules/.bin/tsx src/control-plane/index.ts ...`.
      ExecStart = "${pkgs.nodejs}/lib/node_modules/npm/bin/npm-cli.js run start --ignore-scripts --workspace @niri/runtime -- --host 127.0.0.1 --port 3000 --agents ${niriHome}/agents";
      Environment = [
        "NIRI_HOME=${niriHome}"
        "NIRI_CONTROL_HOME=${niriHome}/control"
      ];
      StateDirectory = "niri";
      Restart = "on-failure";
      RestartSec = "5";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ProtectControlGroups = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      RestrictSUIDSGID = true;
      # sudo is required for the niri-logs helper, so this unit must not
      # forbid privilege elevation.
    };
  };

  # Render the OpenRouter API key into the live agent's YAML from sops so the
  # key is never hand-maintained (mirrors route.nix's cli-proxy-api-key). The
  # live harness runs from /home/molly/niri via a manually-managed container,
  # not ${niriHome}, so this targets that path. A container restart is needed
  # for a rotated key to take effect.
  systemd.services.niri-agent-config = {
    description = "Render sops OpenRouter key into niri agent config";
    after = ["sops-install-secrets.service"];
    wants = ["sops-install-secrets.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      cfg=/home/molly/niri/agents/halo.yaml
      [ -f "$cfg" ] || exit 0
      key="$(cat ${config.sops.secrets."openrouter/api-key".path})"
      tmp="$(mktemp)"
      ${pkgs.gawk}/bin/awk -v key="$key" '
        /^[A-Za-z_][A-Za-z0-9_-]*:/ { inblk = ($0 ~ /^(embedding|summary):/) }
        inblk && /^  apiKey:/ { print "  apiKey: " key; next }
        { print }
      ' "$cfg" >"$tmp"
      ${pkgs.coreutils}/bin/install -o molly -g users -m 0600 "$tmp" "$cfg"
      ${pkgs.coreutils}/bin/rm -f "$tmp"
    '';
  };

  security.sudo.extraRules = [
    {
      users = ["niri"];
      commands = [
        {
          command = "${niri-logs}/bin/niri-logs";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Seed a stopped `ops` agent. Leave it stopped until model credentials are
  # configured; enable by creating it via the niri CLI or setting a seed here.
  # Alternative: seed declaratively with a nix/agent.example.nix-shaped config
  # (mkAgent + secretFromEnv), then `niri seed` once at boot.
  systemd.tmpfiles.rules = [
    "d ${niriHome}/agents 0750 niri niri - -"
    "d ${niriHome}/control 0750 niri niri - -"
  ];
}
