# Convergent, idempotent bootstrap for the media stack. Every step is an
# *upsert*: it creates the object if missing and updates it if present, so
# re-running the service reconciles live drift back to the declared state
# (the old version only created-if-absent, which silently left changed fields
# like removeCompletedDownloads at whatever the WebUI last wrote).
#   - Sonarr/Radarr/Lidarr root folders
#   - qBittorrent download clients (per-app categories + save paths, keeping
#     completed torrents so private trackers keep seeding to the declared ratio)
#   - Seerr connections to Sonarr/Radarr (Seerr has no Lidarr support)
# API keys are read from each app's config at runtime; the qBittorrent WebUI
# password comes from sops. Safe to re-run.
{
  config,
  pkgs,
  ...
}: let
  qbPass = config.sops.secrets."qbittorrent/webui-password".path;

  # Profile names; IDs are looked up at runtime so they never drift.
  sonarrProfile = "Prefer 720p";
  videoProfile = "HD-720p";
  musicProfile = "Standard";
in {
  sops.secrets = {
    "qbittorrent/webui-password" = {
      sopsFile = ../../secrets/misty.yaml;
      mode = "0400";
    };
    "iptorrents/cookie" = {
      sopsFile = ../../secrets/misty.yaml;
      mode = "0400";
    };
    "iptorrents/user-agent" = {
      sopsFile = ../../secrets/misty.yaml;
      mode = "0400";
    };
  };

  # On-demand: a tracker outage must not fail the unrelated arr bootstrap.
  # Prowlarr persists the indexer; start this unit again after cookie rotation.
  systemd.services.prowlarr-iptorrents = {
    description = "Configure IPTorrents indexer from SOPS";
    after = ["prowlarr.service"];
    requires = ["prowlarr.service"];
    path = with pkgs; [curl jq coreutils gnused];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      umask 077
      key=$(sed -n 's:.*<ApiKey>\([^<]*\)</ApiKey>.*:\1:p' /var/lib/prowlarr/config.xml)
      [ -n "$key" ] || { echo 'Prowlarr API key missing' >&2; exit 1; }
      base=http://127.0.0.1:9696/api/v1/indexer
      profile=$(curl -fsS -H "X-Api-Key: $key" http://127.0.0.1:9696/api/v1/appprofile | jq -r '.[] | select(.name=="Standard") | .id')
      [ -n "$profile" ] || { echo 'Prowlarr Standard app profile missing' >&2; exit 1; }
      current=$(curl -fsS -H "X-Api-Key: $key" "$base" | jq -c '.[] | select(.implementation=="IPTorrents")')
      if [ -n "$current" ]; then
        id=$(printf '%s' "$current" | jq -r '.id')
        method=PUT
        url="$base/$id"
      else
        current=$(curl -fsS -H "X-Api-Key: $key" "$base/schema" | jq -c '.[] | select(.implementation=="IPTorrents")')
        [ -n "$current" ] || { echo 'IPTorrents schema missing' >&2; exit 1; }
        method=POST
        url="$base"
      fi
      payload=$(mktemp)
      trap 'rm -f "$payload"' EXIT
      printf '%s' "$current" | jq --argjson profile "$profile" --rawfile cookie ${config.sops.secrets."iptorrents/cookie".path} --rawfile agent ${config.sops.secrets."iptorrents/user-agent".path} '
        .enable = true | .name = "IPTorrents" | .appProfileId = $profile
        | .fields |= map(if .name == "cookie" then .value = $cookie
                       elif .name == "baseUrl" then .value = "https://iptorrents.com/"
                       elif .name == "userAgent" then .value = $agent
                       else . end)' > "$payload"
      code=$(curl -sS -o /dev/null -w '%{http_code}' -H "X-Api-Key: $key" -H 'Content-Type: application/json' --data-binary @"$payload" "$base/test")
      case "$code" in 2??) ;; *) echo "IPTorrents test failed (HTTP $code); indexer not changed" >&2; exit 1 ;; esac
      code=$(curl -sS -o /dev/null -w '%{http_code}' -X "$method" -H "X-Api-Key: $key" -H 'Content-Type: application/json' --data-binary @"$payload" "$url")
      case "$code" in 2??) ;; *) echo "IPTorrents update failed (HTTP $code)" >&2; exit 1 ;; esac
      curl -fsS -H "X-Api-Key: $key" "$base" | jq -e 'any(.[]; .implementation=="IPTorrents" and .enable==true)' >/dev/null
      echo 'IPTorrents indexer configured'
    '';
  };

  systemd.services.arr-bootstrap = {
    description = "Bootstrap the *arr stack (root folders, clients, Seerr links, sign-in)";
    after = ["sonarr.service" "radarr.service" "lidarr.service" "qbittorrent.service" "seerr.service"];
    wants = ["sonarr.service" "radarr.service" "lidarr.service" "qbittorrent.service" "seerr.service"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [curl jq coreutils gnugrep gnused];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      umask 077
      scratch=$(mktemp -d)
      trap 'rm -f "$scratch"/*; rmdir "$scratch"' EXIT

      SONARR=8989
      RADARR=7878
      LIDARR=8686
      SEERR=5055
      QB=8080

      die() { echo "ERROR: $*" >&2; return 1; }

      # Config files are only written once each app has started; wait for them
      # before reading API keys (a freshly enabled app races the bootstrap).
      wait_file() { # path
        for _ in $(seq 1 100); do
          [ -s "$1" ] && return 0
          sleep 3
        done
        die "timed out waiting for $1"
      }

      wait_file /var/lib/sonarr/.config/NzbDrone/config.xml
      wait_file /var/lib/radarr/.config/Radarr/config.xml
      wait_file /var/lib/lidarr/.config/Lidarr/config.xml

      SONARR_KEY=$(sed -n 's:.*<ApiKey>\([^<]*\)</ApiKey>.*:\1:p' /var/lib/sonarr/.config/NzbDrone/config.xml)
      RADARR_KEY=$(sed -n 's:.*<ApiKey>\([^<]*\)</ApiKey>.*:\1:p' /var/lib/radarr/.config/Radarr/config.xml)
      LIDARR_KEY=$(sed -n 's:.*<ApiKey>\([^<]*\)</ApiKey>.*:\1:p' /var/lib/lidarr/.config/Lidarr/config.xml)

      wait_api() { # url apikey
        for _ in $(seq 1 60); do
          curl -sf -H "X-Api-Key: $2" "$1" >/dev/null 2>&1 && return 0
          sleep 3
        done
        die "timed out waiting for $1"
      }

      # Fetch the numeric id of a quality profile by name. Fails loudly if the
      # named profile does not exist, rather than silently using a wrong id.
      profile_id() { # port key apiver name
        local id
        id=$(curl -s -H "X-Api-Key: $2" "http://127.0.0.1:$1/api/$3/qualityprofile" \
              | jq -r --arg n "$4" '.[]|select(.name==$n)|.id' | head -1)
        [ -n "$id" ] || die "quality profile '$4' not found on :$1"
        echo "$id"
      }

      post_check() { # url apikey file expected
        local code
        code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
               -H "X-Api-Key: $2" -H 'Content-Type: application/json' --data @"$3" "$1")
        [ "$code" = "$4" ] || die "POST $1 returned HTTP $code (want $4)"
      }

      put_check() { # url apikey file
        local code
        code=$(curl -s -o /dev/null -w '%{http_code}' -X PUT \
               -H "X-Api-Key: $2" -H 'Content-Type: application/json' --data @"$3" "$1")
        [ "$code" = "200" ] || [ "$code" = "202" ] || die "PUT $1 returned HTTP $code (want 200/202)"
      }

      # --- root folders (create-if-absent; path is the stable key) ---
      add_rootfolder() { # port key path apiver
        local ver=''${4:-v3}
        if ! curl -s -H "X-Api-Key: $2" "http://127.0.0.1:$1/api/$ver/rootfolder" | jq -e --arg p "$3" 'any(.path==$p)' >/dev/null; then
          jq -n --arg p "$3" '{path:$p}' | curl -s -X POST -H "X-Api-Key: $2" -H 'Content-Type: application/json' --data @- "http://127.0.0.1:$1/api/$ver/rootfolder" >/dev/null
          echo "added root folder $3 on :$1"
        else
          echo "root folder $3 on :$1 already present"
        fi
      }

      # --- qBittorrent *download client* (upsert) ---
      # If a client named qBittorrent exists, update it in place; otherwise
      # create from the implementation schema. Either way the result is PUT/POSTed
      # and then verified with the client's own test endpoint.
      upsert_qbclient() { # port key apiver category
        local port=$1 key=$2 ver=$3 cat=$4
        local existing id payload
        existing=$(curl -s -H "X-Api-Key: $key" "http://127.0.0.1:$port/api/$ver/downloadclient")
        id=$(echo "$existing" | jq -r '.[]|select(.name=="qBittorrent")|.id' | head -1)

        if [ -n "$id" ]; then
          payload=$(echo "$existing" | jq -c --rawfile pw ${qbPass} --arg cat "$cat" --argjson id "$id" '
            .[]|select(.id==$id)
            | .enable = true
            | .removeCompletedDownloads = false
            | .removeFailedDownloads = true
            | .fields |= map(
                if .name == "host" then .value = "127.0.0.1"
                elif .name == "port" then .value = 8080
                elif .name == "username" then .value = "admin"
                elif .name == "password" then .value = $pw
                elif (.name | test("^(tv|movie|music)Category$")) then .value = $cat
                else . end)')
          printf '%s' "$payload" > "$scratch/qbclient.json"
          put_check "http://127.0.0.1:$port/api/$ver/downloadclient/$id" "$key" "$scratch/qbclient.json"
          echo "updated qBittorrent client (category $cat) on :$port"
        else
          local schema
          schema=$(curl -s -H "X-Api-Key: $key" "http://127.0.0.1:$port/api/$ver/downloadclient/schema" | jq -c '.[]|select(.implementation=="QBittorrent")')
          [ -n "$schema" ] || die "no QBittorrent schema on :$port"
          payload=$(jq -n --argjson s "$schema" --rawfile pw ${qbPass} --arg cat "$cat" '
            $s
            | .enable = true
            | .name = "qBittorrent"
            | .priority = 1
            | .removeCompletedDownloads = false
            | .removeFailedDownloads = true
            | .fields |= map(
                if .name == "host" then .value = "127.0.0.1"
                elif .name == "port" then .value = 8080
                elif .name == "username" then .value = "admin"
                elif .name == "password" then .value = $pw
                elif (.name | test("^(tv|movie|music)Category$")) then .value = $cat
                else . end)')
          printf '%s' "$payload" > "$scratch/qbclient.json"
          post_check "http://127.0.0.1:$port/api/$ver/downloadclient" "$key" "$scratch/qbclient.json" 201
          echo "added qBittorrent client (category $cat) on :$port"
        fi

        post_check "http://127.0.0.1:$port/api/$ver/downloadclient/test" "$key" "$scratch/qbclient.json" 200
        echo "qBittorrent client (category $cat) on :$port test OK"
      }

      # --- qBittorrent category with save path (upsert) ---
      upsert_qbcat() { # name savepath
        curl -s -c "$scratch/qbcookies" -X POST --data-urlencode "username=admin" --data-urlencode "password@${qbPass}" "http://127.0.0.1:$QB/api/v2/auth/login" >/dev/null
        if curl -s -b "$scratch/qbcookies" "http://127.0.0.1:$QB/api/v2/torrents/categories" | jq -e --arg c "$1" 'has($c)' >/dev/null; then
          curl -sf -b "$scratch/qbcookies" -X POST --data-urlencode "category=$1" --data-urlencode "savePath=$2" "http://127.0.0.1:$QB/api/v2/torrents/editCategory" >/dev/null \
            || die "failed to edit qBittorrent category $1"
          echo "updated qBittorrent category $1 -> $2"
        else
          curl -sf -b "$scratch/qbcookies" -X POST --data-urlencode "category=$1" --data-urlencode "savePath=$2" "http://127.0.0.1:$QB/api/v2/torrents/createCategory" >/dev/null \
            || die "failed to create qBittorrent category $1"
          echo "created qBittorrent category $1 -> $2"
        fi
      }

      wait_api "http://127.0.0.1:$SONARR/api/v3/system/status" "$SONARR_KEY"
      wait_api "http://127.0.0.1:$RADARR/api/v3/system/status" "$RADARR_KEY"
      wait_api "http://127.0.0.1:$LIDARR/api/v1/system/status" "$LIDARR_KEY"

      # Start with Sonarr's Any profile so all known qualities remain eligible,
      # then put 720p qualities last (highest priority in Sonarr's ordered list).
      profiles=$(curl -fsS -H "X-Api-Key: $SONARR_KEY" "http://127.0.0.1:$SONARR/api/v3/qualityprofile")
      profile=$(printf '%s' "$profiles" | jq -c --arg n "${sonarrProfile}" '.[]|select(.name==$n)')
      if [ -n "$profile" ]; then
        existing_profile_id=$(printf '%s' "$profile" | jq -r '.id')
        profile_url="http://127.0.0.1:$SONARR/api/v3/qualityprofile/$existing_profile_id"
      else
        profile=$(printf '%s' "$profiles" | jq -c '.[]|select(.name=="Any")|del(.id)')
        [ -n "$profile" ] || die 'Sonarr Any profile missing'
        profile_url="http://127.0.0.1:$SONARR/api/v3/qualityprofile"
      fi
      printf '%s' "$profile" | jq -c --arg n "${sonarrProfile}" '
        def is720: ((.quality.name // "") + " " + ([.items[]?.quality.name] | join(" "))) | contains("720p");
        .name=$n | .upgradeAllowed=false | .cutoff=4
        | .items |= (map(if .quality.id==0 then . else .allowed=true | .items |= map(.allowed=true) end)
                     | (map(select(is720 | not)) + map(select(is720))))' > "$scratch/sonarr-profile.json"
      if [ -n "''${existing_profile_id:-}" ]; then
        put_check "$profile_url" "$SONARR_KEY" "$scratch/sonarr-profile.json"
      else
        post_check "$profile_url" "$SONARR_KEY" "$scratch/sonarr-profile.json" 201
      fi

      SONARR_VIDEO_ID=$(profile_id "$SONARR" "$SONARR_KEY" v3 "${sonarrProfile}")
      RADARR_VIDEO_ID=$(profile_id "$RADARR" "$RADARR_KEY" v3 "${videoProfile}")
      LIDARR_MUSIC_ID=$(profile_id "$LIDARR" "$LIDARR_KEY" v1 "${musicProfile}")
      LIDARR_META_ID=$(curl -s -H "X-Api-Key: $LIDARR_KEY" "http://127.0.0.1:$LIDARR/api/v1/metadataprofile" | jq -r '.[]|select(.name=="Standard")|.id' | head -1)

      add_rootfolder "$SONARR" "$SONARR_KEY" "/srv/tv/media/tv"
      add_rootfolder "$RADARR" "$RADARR_KEY" "/srv/movies/media/movies"

      # Lidarr root folder carries default profiles/monitor options.
      if ! curl -s -H "X-Api-Key: $LIDARR_KEY" "http://127.0.0.1:$LIDARR/api/v1/rootfolder" | jq -e 'any(.path=="/srv/movies/media/music")' >/dev/null; then
        jq -n --argjson q "$LIDARR_MUSIC_ID" --argjson m "$LIDARR_META_ID" \
          '{name:"music",path:"/srv/movies/media/music",defaultQualityProfileId:$q,defaultMetadataProfileId:$m,defaultMonitorOption:"all",defaultNewItemMonitorOption:"all",defaultTags:[],isCalibreLibrary:false}' \
          | curl -s -X POST -H "X-Api-Key: $LIDARR_KEY" -H 'Content-Type: application/json' --data @- "http://127.0.0.1:$LIDARR/api/v1/rootfolder" >/dev/null
        echo "added root folder /srv/movies/media/music on :$LIDARR"
      else
        echo "root folder /srv/movies/media/music on :$LIDARR already present"
      fi

      upsert_qbcat "tv" "/srv/tv/torrents/tv"
      upsert_qbcat "movies" "/srv/movies/torrents/movies"
      upsert_qbcat "music" "/srv/movies/torrents/music"
      upsert_qbclient "$SONARR" "$SONARR_KEY" "v3" "tv"
      upsert_qbclient "$RADARR" "$RADARR_KEY" "v3" "movies"
      upsert_qbclient "$LIDARR" "$LIDARR_KEY" "v1" "music"

      # --- Seerr connections (movies/TV only) ---
      SEERR_KEY=$(jq -r '.main.apiKey' /var/lib/seerr/settings.json)
      for _ in $(seq 1 60); do curl -sf -H "X-Api-Key: $SEERR_KEY" "http://127.0.0.1:$SEERR/api/v1/settings/main" >/dev/null 2>&1 && break; sleep 3; done

      # Enforce sign-in methods: Jellyfin (Quick Connect) only, no local email
      # or Plex. Seerr has no declarative config, so reconcile runtime drift.
      curl -s -H "X-Api-Key: $SEERR_KEY" "http://127.0.0.1:$SEERR/api/v1/settings/main" \
        | jq -c 'del(.apiKey) | .localLogin=false | .newPlexLogin=false | .mediaServerLogin=true' > "$scratch/seerr-main.json"
      post_check "http://127.0.0.1:$SEERR/api/v1/settings/main" "$SEERR_KEY" "$scratch/seerr-main.json" 200
      echo "enforced Seerr sign-in: Jellyfin only"

      # Upsert a Seerr service entry, pointing it at the discovered profile.
      # Seerr's activeDirectory must be a library root, not a torrent staging
      # path; otherwise Sonarr/Radarr reject requests before any search.
      upsert_seerr() { # kind port key profileid profilename directory
        local kind=$1 port=$2 key=$3 profileid=$4 profilename=$5 dir=$6
        local id
        id=$(curl -s -H "X-Api-Key: $SEERR_KEY" "http://127.0.0.1:$SEERR/api/v1/settings/$kind" | jq -r '.[0].id // empty')
        if [ -n "$id" ]; then
          curl -s -H "X-Api-Key: $SEERR_KEY" "http://127.0.0.1:$SEERR/api/v1/settings/$kind" \
            | jq -c --argjson p "$profileid" --arg n "$profilename" --arg dir "$dir" \
                '.[0] | del(.id)
                 | .activeProfileId=$p
                 | .activeProfileName=$n
                 | .activeAnimeProfileId=$p
                 | .activeAnimeProfileName=$n
                 | .activeDirectory=$dir' > "$scratch/seerr.json"
          put_check "http://127.0.0.1:$SEERR/api/v1/settings/$kind/$id" "$SEERR_KEY" "$scratch/seerr.json"
          echo "updated Seerr -> $kind (profile $profilename)"
        else
          jq -n --arg k "$key" --argjson p "$profileid" --arg n "$profilename" --argjson port "$port" --arg dir "$dir" \
            '{name:("'"$kind"'"|ascii_upcase),hostname:"127.0.0.1",port:$port,apiKey:$k,useSsl:false,baseUrl:"",activeDirectory:$dir,activeProfileId:$p,activeProfileName:$n,activeAnimeProfileId:$p,activeAnimeProfileName:$n,tags:[],is4k:false,isDefault:true,syncEnabled:true,preventSearch:false,tagRequests:false}' \
            > "$scratch/seerr.json"
          post_check "http://127.0.0.1:$SEERR/api/v1/settings/$kind" "$SEERR_KEY" "$scratch/seerr.json" 201
          echo "connected Seerr -> $kind (profile $profilename)"
        fi
      }

      upsert_seerr "sonarr" 8989 "$SONARR_KEY" "$SONARR_VIDEO_ID" "${sonarrProfile}" "/srv/tv/media/tv"
      upsert_seerr "radarr" 7878 "$RADARR_KEY" "$RADARR_VIDEO_ID" "${videoProfile}" "/srv/movies/media/movies"

      echo "arr-bootstrap done"
    '';
  };
}
