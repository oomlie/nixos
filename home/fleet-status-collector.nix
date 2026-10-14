{pkgs, ...}: let
  # Pushes a fleet snapshot to the fleet-status Gatekeeper's ingest route. Runs as a user service
  # because gathering halo's failed units is an SSH as `molly` (root on chi has no key), and because
  # the credentials live in the login keyring, not in root-only sops.
  #
  # Read-only: it reports failed systemd units and chi's last backup time. It cannot change anything.
  collector = pkgs.writeShellApplication {
    name = "fleet-status-collector";
    runtimeInputs = with pkgs; [curl jq libsecret openssh systemd coreutils];
    text = ''
      set -euo pipefail
      api="https://os.daze.lol/gatekeeper/fleet-status/ingest"

      cid="$(secret-tool lookup service fleet-collector user access-client-id)"
      secret="$(secret-tool lookup service fleet-collector user access-client-secret)"
      ingest="$(secret-tool lookup service fleet-collector user ingest-token)"
      for v in "$cid" "$secret" "$ingest"; do
        [ -n "$v" ] || { echo "fleet-status-collector: missing keyring entry" >&2; exit 1; }
      done

      # One unit name per line -> JSON array.
      units() { jq -R -s 'split("\n") | map(select(length > 0))'; }

      chi="$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | units)"

      hosts="$(jq -n --argjson units "$chi" '[{name: "chi", failedUnits: $units, borgLastSuccess: null}]')"

      # halo, only when it answers: an unreachable host is omitted rather than shown as healthy.
      if halo_raw="$(ssh -o BatchMode=yes -o ConnectTimeout=8 halo 'systemctl --failed --no-legend --plain' 2>/dev/null)"; then
        halo="$(printf '%s\n' "$halo_raw" | awk 'NF {print $1}' | units)"
        hosts="$(jq -c --argjson units "$halo" '. + [{name: "halo", failedUnits: $units, borgLastSuccess: null}]' <<<"$hosts")"
      fi

      # chi's backup freshness: the last run of the borg unit, but only when it did not fail.
      if ! systemctl is-failed -q borgbackup-job-misty.service 2>/dev/null; then
        ts="$(systemctl show -p ExecMainExitTimestamp --value borgbackup-job-misty.service 2>/dev/null || true)"
        case "$ts" in
          "" | "n/a" | *@*) : ;;
          *)
            iso="$(date -u -d "$ts" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"
            [ -n "$iso" ] && hosts="$(jq -c --arg iso "$iso" 'map(if .name == "chi" then .borgLastSuccess = $iso else . end)' <<<"$hosts")"
            ;;
        esac
      fi

      body="$(jq -nc --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson hosts "$hosts" '{generatedAt: $at, hosts: $hosts}')"

      curl -fsS -X POST "$api" \
        -H "CF-Access-Client-Id: $cid" \
        -H "CF-Access-Client-Secret: $secret" \
        -H "Authorization: Bearer $ingest" \
        -H "Content-Type: application/json" \
        --data "$body"
      echo
    '';
  };
in {
  home.packages = [collector];

  systemd.user.services.fleet-status-collector = {
    Unit.Description = "Push a fleet-status snapshot to Cloudflare OS";
    Service = {
      Type = "oneshot";
      ExecStart = "${collector}/bin/fleet-status-collector";
    };
  };

  systemd.user.timers.fleet-status-collector = {
    Unit.Description = "Hourly fleet-status snapshot";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
