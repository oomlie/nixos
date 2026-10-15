{
  pkgs,
  inputs,
  ...
}: let
  # The deploy bridge's fleet half. It polls the gatekeeper for approved deploy requests, refuses
  # anything that is not a known host at a revision already on origin/main with a green CI run, builds
  # it, and then **activates** it: `nixos-rebuild switch` for chi (the local machine), `clan machines
  # update` for the others.
  #
  # A deploy here was already approved by a human in Cloudflare OS, which is the gate that matters; the
  # runner's own checks stop an approved-but-unsafe job (unknown host, unpublished revision, red CI)
  # from ever reaching a machine. Store any value under the keyring entry
  # `service=fleet-deploy user=hold`, or create the file below, to pause activation and go back to
  # build-only without changing this module.
  #
  # Runs as a user service: the credentials are in the login keyring and `gh`/`git`/`clan` are molly's.
  clan = inputs.clan-core.packages.${pkgs.stdenv.hostPlatform.system}.clan-cli;
  runner = pkgs.writeShellApplication {
    name = "fleet-deploy-runner";
    runtimeInputs = with pkgs; [curl jq libsecret git gh nix coreutils gnugrep sudo clan];
    # SC2024 warns that `sudo` does not affect a redirect. That is exactly what is wanted here: the
    # activation log should be written by the user's own shell, not by root.
    excludeShellChecks = ["SC2024"];
    text = ''
      set -euo pipefail
      repo="''${FLEET_REPO:-$HOME/nixos}"
      api="https://os.daze.lol/gatekeeper/fleet-status"
      allowed="chi halo"
      hold_file="''${XDG_STATE_HOME:-$HOME/.local/state}/fleet-deploy/hold"

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
      report() { call -X POST "$api/deploy/status" --data "$1" >/dev/null; }

      # Hold switch: an explicit request to stop short of activating.
      held=0
      [ -e "$hold_file" ] && held=1
      [ -n "$(secret-tool lookup service fleet-deploy user hold 2>/dev/null || true)" ] && held=1

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
        if ! nix build --no-link "$worktree#nixosConfigurations.$host.config.system.build.toplevel" >/dev/null 2>&1; then
          report "$(say failed "build of $host at $rev failed")"
          git -C "$repo" worktree remove --force "$worktree"
          continue
        fi

        if [ "$held" = 1 ]; then
          report "$(say built "$host built at $rev; activation held")"
          git -C "$repo" worktree remove --force "$worktree"
          continue
        fi

        report "$(say activating "activating $host at $rev")"
        log="''${XDG_STATE_HOME:-$HOME/.local/state}/fleet-deploy/job-$id.log"
        mkdir -p "$(dirname "$log")"
        if [ "$host" = "chi" ]; then
          # chi is the local machine; it is activated with nixos-rebuild, not clan.
          if sudo -n nixos-rebuild switch --flake "$worktree#$host" >"$log" 2>&1; then
            report "$(say deployed "$host activated at $rev")"
          else
            report "$(say failed "activation of $host at $rev failed; see $log")"
          fi
        else
          if (cd "$worktree" && clan machines update "$host" >"$log" 2>&1); then
            report "$(say deployed "$host activated at $rev")"
          else
            report "$(say failed "activation of $host at $rev failed; see $log")"
          fi
        fi
        git -C "$repo" worktree remove --force "$worktree"
      done < <(jq -c '.[]' <<<"$jobs")
    '';
  };
in {
  home.packages = [runner];

  systemd.user.services.fleet-deploy-runner = {
    Unit.Description = "Validate, build and activate approved Cloudflare OS deploy requests";
    Service = {
      Type = "oneshot";
      ExecStart = "${runner}/bin/fleet-deploy-runner";
      # Activation is long; give it room and keep a record in the journal.
      TimeoutStartSec = "2h";
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
