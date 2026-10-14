{pkgs, ...}: let
  # Exports what can be exported of the Cloudflare OS deployment into a directory that chi's borg job
  # already covers (hosts/chi/configuration.nix). It reads the Cloudflare token from the login keyring,
  # the same entry infra/cloudflare uses, so no new secret is introduced.
  #
  # NOT covered: the Workshop's Durable Object (SQLite) storage -- users, gadgets, workspaces -- which
  # Cloudflare offers no export for. Only KV namespaces and the R2 bucket are saved.
  cloudflare-state-backup = pkgs.writeShellApplication {
    name = "cloudflare-state-backup";
    runtimeInputs = with pkgs; [curl jq libsecret coreutils];
    text = ''
      account=ab50bec72354666a941823793fef426a
      api="https://api.cloudflare.com/client/v4/accounts/$account"
      dest="''${XDG_DATA_HOME:-$HOME/.local/share}/cloudflare-state"
      bucket=daze-os-workshop-blueprint-content

      token="$(secret-tool lookup service cloudflare user token)"
      [ -n "$token" ] || { echo "cloudflare-state-backup: no token in the keyring" >&2; exit 1; }
      get() { curl -fsS --retry 3 -H "Authorization: Bearer $token" "$@"; }

      umask 077
      mkdir -p "$dest"
      work="$(mktemp -d "$dest/.run.XXXXXX")"
      trap 'rm -rf "$work"' EXIT

      # KV: every namespace belonging to this deployment, keys plus values (values can be binary).
      get "$api/storage/kv/namespaces?per_page=100" \
        | jq -c '.result[] | select(.title | startswith("daze-os-")) | {id, title}' > "$work/namespaces.jsonl"

      while IFS= read -r ns; do
        id="$(jq -r .id <<<"$ns")"; title="$(jq -r .title <<<"$ns")"
        dir="$work/kv/$title"; mkdir -p "$dir/values"
        cursor=""; : > "$dir/keys.jsonl"
        while :; do
          page="$(get "$api/storage/kv/namespaces/$id/keys?limit=1000''${cursor:+&cursor=$cursor}")"
          jq -c '.result[]' <<<"$page" >> "$dir/keys.jsonl"
          cursor="$(jq -r '.result_info.cursor // ""' <<<"$page")"
          [ -n "$cursor" ] || break
        done
        # Each line carries the key both as JSON (exact) and percent-encoded (path/filename). The
        # Context namespace has a key containing a NUL byte, which bash would silently truncate and
        # which the single-value endpoint rejects, so such a key is read through bulk/get from its
        # JSON form instead (text only, which is what Context stores).
        while IFS= read -r line; do
          enc="$(jq -r .e <<<"$line")"
          if ! get "$api/storage/kv/namespaces/$id/values/$enc" -o "$dir/values/$enc" 2>/dev/null; then
            get -X POST -H "Content-Type: application/json" \
              --data "$(jq -c '{keys: [.n], type: "text"}' <<<"$line")" \
              "$api/storage/kv/namespaces/$id/bulk/get" \
              | jq -j --argjson l "$line" '.result.values[$l.n]' > "$dir/values/$enc"
          fi
        done < <(jq -c '{n: .name, e: (.name | @uri)}' "$dir/keys.jsonl")
      done < "$work/namespaces.jsonl"

      # R2: the blueprint bundle bucket.
      mkdir -p "$work/r2/$bucket"
      cursor=""
      while :; do
        page="$(get "$api/r2/buckets/$bucket/objects?per_page=1000''${cursor:+&cursor=$cursor}")"
        jq -r '.result[].key | @uri' <<<"$page" | while IFS= read -r key; do
          get "$api/r2/buckets/$bucket/objects/$key" -o "$work/r2/$bucket/$key"
        done
        cursor="$(jq -r '.result_info.cursor // ""' <<<"$page")"
        [ -n "$cursor" ] || break
      done

      jq -n --arg at "$(date -u +%FT%TZ)" \
        --argjson kvKeys "$(cat "$work"/kv/*/keys.jsonl | wc -l)" \
        --argjson r2Objects "$(find "$work/r2" -type f | wc -l)" \
        '{exportedAt: $at, kvKeys: $kvKeys, r2Objects: $r2Objects}' > "$work/manifest.json"

      # Swap in only after a complete export, so a failed run leaves the previous one intact.
      rm -rf "$dest/latest.old"
      [ ! -e "$dest/latest" ] || mv "$dest/latest" "$dest/latest.old"
      mv "$work" "$dest/latest"
      trap - EXIT
      rm -rf "$dest/latest.old"
      cat "$dest/latest/manifest.json"
    '';
  };
in {
  home.packages = [cloudflare-state-backup];

  systemd.user.services.cloudflare-state-backup = {
    Unit.Description = "Export Cloudflare OS KV and R2 state for borg";
    Service = {
      Type = "oneshot";
      ExecStart = "${cloudflare-state-backup}/bin/cloudflare-state-backup";
    };
  };

  # Persistent so a laptop that was asleep at the scheduled time catches up when it wakes.
  systemd.user.timers.cloudflare-state-backup = {
    Unit.Description = "Daily Cloudflare OS state export";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
