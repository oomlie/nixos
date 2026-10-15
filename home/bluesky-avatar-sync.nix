{pkgs, ...}: let
  # Keeps the Cloudflare OS avatar (the Workshop's AVATARS KV) matching the account's Bluesky
  # picture. The OS stores avatars raw, keyed by the Access email, and only accepts JPEG or PNG up
  # to 100 KB -- Bluesky serves WebP -- so this fetches the profile, converts, and puts it.
  #
  # Runs as a user service: the KV write uses the scoped deploy token in the login keyring.
  sync = pkgs.writeShellApplication {
    name = "bluesky-avatar-sync";
    runtimeInputs = with pkgs; [curl jq imagemagick libsecret coreutils];
    text = ''
      set -euo pipefail
      actor="''${BLUESKY_ACTOR:-molly.computer}"
      key="''${OS_AVATAR_KEY:-mwund@proton.me}"
      account=ab50bec72354666a941823793fef426a
      namespace=26a1adcf46f4426fa4f38d1962801216

      token="$(secret-tool lookup service cloudflare-deploy user molly)"
      [ -n "$token" ] || { echo "bluesky-avatar-sync: no deploy token in the keyring" >&2; exit 1; }

      profile="$(curl -fsS "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=$actor")"
      url="$(jq -r '.avatar // empty' <<<"$profile")"
      [ -n "$url" ] || { echo "bluesky-avatar-sync: $actor has no avatar"; exit 0; }

      state="''${XDG_STATE_HOME:-$HOME/.local/state}/bluesky-avatar-sync"
      mkdir -p "$state"
      if [ "$(cat "$state/last" 2>/dev/null || true)" = "$url" ]; then
        echo "bluesky-avatar-sync: unchanged"
        exit 0
      fi

      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      curl -fsS -o "$work/avatar" "$url"
      # Normalise: square, stripped, JPEG, small enough for the Workshop's 100 KB limit.
      magick "$work/avatar" -resize 256x256^ -gravity center -extent 256x256 -strip -quality 85 "$work/avatar.jpg"
      size="$(wc -c < "$work/avatar.jpg")"
      [ "$size" -le 102400 ] || { echo "bluesky-avatar-sync: converted avatar is $size bytes" >&2; exit 1; }

      encoded="$(jq -rn --arg k "$key" '$k|@uri')"
      curl -fsS -o /dev/null -X PUT \
        "https://api.cloudflare.com/client/v4/accounts/$account/storage/kv/namespaces/$namespace/values/$encoded" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: image/jpeg" \
        --data-binary @"$work/avatar.jpg"

      printf '%s' "$url" > "$state/last"
      echo "bluesky-avatar-sync: updated ($size bytes)"
    '';
  };
in {
  home.packages = [sync];

  systemd.user.services.bluesky-avatar-sync = {
    Unit.Description = "Sync the Cloudflare OS avatar with Bluesky";
    Service = {
      Type = "oneshot";
      ExecStart = "${sync}/bin/bluesky-avatar-sync";
    };
  };

  systemd.user.timers.bluesky-avatar-sync = {
    Unit.Description = "Sync the Cloudflare OS avatar daily";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
