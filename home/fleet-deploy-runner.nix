{pkgs, ...}: let
  # The deploy bridge's fleet half. It polls the gatekeeper for approved deploy requests, refuses
  # anything that is not a known host at a revision already on origin/main with a green CI run, and
  # builds that revision. It does NOT activate: building is the expensive, validating step, and the
  # switch is left to a human (`nixos-rebuild switch` on chi, `clan machines update halo`). Turning
  # activation on here would let an approved request change production unattended; that is a
  # deliberate, separate step.
  #
  # Runs as a user service: the credentials are in the login keyring and `gh`/`git` are molly's.
  runner = pkgs.writeShellApplication {
    name = "fleet-deploy-runner";
    runtimeInputs = with pkgs; [curl jq libsecret git gh nix coreutils gnugrep];
    text = ''
      set -euo pipefail
      repo="''${FLEET_REPO:-$HOME/nixos}"
      api="https://os.daze.lol/gatekeeper/fleet-status"
      allowed="chi halo"

      cid="$(secret-tool lookup service fleet-collector user access-client-id)"
      secret="$(secret-tool lookup service fleet-collector user access-client-secret)"
      ingest="$(secret-tool lookup service fleet-collector user ingest-token)"
      for v in "$cid" "$secret" "$ingest"; do
        [ -n "$v" ] || { echo "fleet-deploy-runner: missing keyring entry" >&2; exit 1; }
      done

      call() {
        curl -fsS -H "CF-Access-Client-Id: $cid" -H "CF-Access-Client-Secret: $secret" \
          -H "Authorization: Bearer $ingest" -H "Content-Type: application/json" "$@"
      }
      # Report a job's new state back to the gatekeeper.
      report() { call -X POST "$api/deploy/status" --data "$1" >/dev/null; }

      git -C "$repo" fetch -q origin

      jobs="$(call "$api/deploy/jobs")"
      [ "$jobs" != "[]" ] || exit 0

      while IFS= read -r row; do
        id="$(jq -r .id <<<"$row")"
        host="$(jq -r .host <<<"$row")"
        rev="$(jq -r .rev <<<"$row")"
        say() { jq -nc --argjson id "$id" --arg state "$1" --arg message "$2" \
          '{id: $id, state: $state, message: $message}'; }

        if ! grep -qw -- "$host" <<<"$allowed"; then
          report "$(say rejected "host '$host' is not one this runner deploys")"; continue
        fi
        if ! git -C "$repo" merge-base --is-ancestor "$rev" origin/main 2>/dev/null; then
          report "$(say rejected "commit $rev is not on origin/main")"; continue
        fi
        if ! gh run list -R oomlie/nixos -c "$rev" --limit 1 \
             --json status,conclusion --jq '.[0] | select(.status == "completed" and .conclusion == "success") | .conclusion' \
             2>/dev/null | grep -q success; then
          report "$(say rejected "no successful CI run for $rev")"; continue
        fi

        report "$(say running "building $host at $rev")"
        worktree="$(mktemp -d)"
        git -C "$repo" worktree add -q --detach "$worktree" "$rev"
        if nix build --no-link "$worktree#nixosConfigurations.$host.config.system.build.toplevel" >/dev/null 2>&1; then
          report "$(say built "$host built at $rev; activation left to a human")"
        else
          report "$(say failed "build of $host at $rev failed")"
        fi
        git -C "$repo" worktree remove --force "$worktree"
      done < <(jq -c '.[]' <<<"$jobs")
    '';
  };
in {
  home.packages = [runner];

  systemd.user.services.fleet-deploy-runner = {
    Unit.Description = "Validate and build approved Cloudflare OS deploy requests";
    Service = {
      Type = "oneshot";
      ExecStart = "${runner}/bin/fleet-deploy-runner";
    };
  };

  systemd.user.timers.fleet-deploy-runner = {
    Unit.Description = "Poll for approved deploy requests every 10 minutes";
    Timer = {
      OnCalendar = "*:0/10";
      Persistent = true;
      RandomizedDelaySec = "2m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
