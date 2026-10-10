# Host: misty

## System Overview & Role

- **Role**: Primary home media server, high-capacity storage vault, YouTube frontend proxy, and LAN kiosk display host.
- **OS**: NixOS 26.11 (Zokor), declaratively managed via Flake (`nixosConfigurations.misty` in `/root/halo-nixos`).
- **Network**: `192.168.1.174` on `eno1` (onboard Gigabit NIC with static router DHCP reservation).

---

## Hardware Profile

- **CPU**: Intel Xeon CPU E5-1650 v4 @ 3.60GHz (6 physical cores, 12 threads).
- **RAM**: 64 GB DDR4 (62 GiB total usable, 16 GiB zramSwap at 25% memory percent + 15 GiB disk swap).
- **GPU**: NVIDIA Quadro K620 (2 GB VRAM, Maxwell architecture), configured using `boot.kernelPackages.nvidiaPackages.legacy_580` (modesetting enabled) for NVENC hardware-accelerated video transcoding in Jellyfin.
- **Motherboard / Platform**: Lenovo X99 workstation/server platform.

---

## Storage Architecture & Disk Topology

Managed declaratively via Disko (`hosts/misty/storage.nix`) without RAID or disk encryption:

1. **Boot / System SSD**: 512 GB SanDisk SSD (`/dev/sda`, model `SD8SB8U512G1001_174023800693`)
   - `/boot`: 1 GB FAT32 ESP partition
   - `/`: 475.9 GB ext4 root partition (Nix store, system state, containers)
2. **Movies & Music HDD**: 12 TB Seagate HDD (`/dev/sdc`, model `ST12000DM0007-2GR116_ZJV0SB18`)
   - Mounted at `/srv/movies` (ext4, `noatime`)
   - Directory hierarchy: `/srv/movies/media/movies`, `/srv/movies/media/music`, `/srv/movies/torrents/...`, `/srv/movies/usenet/...`
   - Bind mount: `/srv/movies/media/music` bind-mounted to `/srv/music` for clean presentation in LAN media tools.
3. **TV Shows HDD**: 12 TB Seagate HDD (`/dev/sdb`, model `ST12000DM0007-2GR116_ZJV43VB9`)
   - Mounted at `/srv/tv` (ext4, `noatime`)
   - Directory hierarchy: `/srv/tv/media/tv`, `/srv/tv/torrents/tv`, `/srv/tv/usenet/...`

> **Storage Design Rationale**: Media categories (Movies+Music vs. TV) are isolated onto separate 12 TB hard drives along with their matching download staging directories (`torrents` / `usenet`). Keeping downloads and the target library on the same physical filesystem guarantees instant atomic file moves and hardlinks across qBittorrent, Usenet downloadders, and Servarr services without cross-device copy overhead.

---

## Media & Servarr Stack

Shared media permissions:
- All media services (`sonarr`, `radarr`, `lidarr`, `prowlarr`, `bazarr`, `jellyfin`, `qbittorrent`, `navidrome`, `filebrowser`) share the `media` system group (`gid 2775` with setgid directories and `umask 0002`) for seamless group-writable file management.

### Services & Ports Summary

| Service | Function | Port | Storage / Notes |
|---|---|---|---|
| **Jellyfin** | Media streaming server | `8096` | NVENC hardware transcoding via `/dev/nvidia0` |
| **Navidrome** | Audio / Music streaming | `4533` | Serves `/srv/music` (LAN accessible) |
| **Seerr** | Request manager | `5055` | Media request interface for Jellyfin |
| **qBittorrent** | BitTorrent client | `8080` (UI), `42764` (Peer) | Downloads to `/srv/movies/torrents` & `/srv/tv/torrents` |
| **Sonarr** | TV show automation | `8989` | Automates `/srv/tv` |
| **Radarr** | Movie automation | `7878` | Automates `/srv/movies/media/movies` |
| **Lidarr** | Music automation | `8686` | Automates `/srv/movies/media/music` |
| **Bazarr** | Subtitle manager | `6767` | Fetches subtitles for TV & movies |
| **Prowlarr** | Indexer manager | `9696` | Syncs indexers across Servarr stack |
| **FileBrowser** | File manager & upload tool | `8088` | "Misty Media Uploads", roots at `/srv` |

---

## Web Services & Auth Infrastructure

- **Invidious (`yt.daze.lol`)**: Custom Crystal build with OIDC support (`invidious-oidc`) listening on port `3000`.
  - **Database**: Local PostgreSQL (`invidious` user & DB on port `5432`).
  - **Authentication**: Gated behind `ratlogin` (`https://auth.daze.lol`). Local password forms are hidden (`oidc_only = true`, `private_instance = true`).
  - **Invidious Companion**: Deno-based YouTube stream fetcher (`quay.io/invidious/invidious-companion:latest`) running via Podman on host network port `8282`.
- **Secret Management**: Handled declaratively with `sops-nix` referencing `secrets/misty.yaml` (SOPS age key located at `/var/lib/sops-nix/keys.txt`).

---

## Display & Kiosk System

- **Compositor**: Wayland Cage compositor (`cage-tty1.service`) running under dedicated user `tv`.
- **Output**: DisplayPort `DP-1` (`/dev/dri/card1`).
- **Application**: Chromium running in kiosk mode (`--kiosk --ozone-platform=wayland`) pointing directly to `https://video.daze.lol`.

---

## Operational Runbook & Diagnostics

### Checking Service Status & GPU
```bash
# Check status of core media and web services
systemctl status jellyfin.service invidious.service filebrowser.service navidrome.service --no-pager

# Check NVIDIA GPU status & transcode sessions
nvidia-smi

# Check storage utilization
df -h / /srv/movies /srv/tv
```

### Inspecting Logs
```bash
# Invidious & Companion logs
journalctl -u invidious.service -f
journalctl -u podman-invidious-companion.service -f

# Jellyfin logs
journalctl -u jellyfin.service -f

# FileBrowser logs
journalctl -u filebrowser.service -f
```

### Rebuilding Host & Nix Maintenance
```bash
# Apply host configuration changes with nh
nh os switch /root/halo-nixos --flake .#misty

# Clean old Nix store generations (automated via nh-clean.timer)
nh clean all --keep 5 --keep-since 7d
```

---

## Headscale Tailnet Integration (Raff Technologies Plan)

To securely connect `halo` and `misty` across networks without exposing internal media ports to the public internet:

1. **Headscale Control Plane Node (Raff Technologies VPS)**:
   - Configured in `hosts/headscale/configuration.nix` and `hardware-configuration.nix`.
   - Domain: `head.daze.lol` (DNS-only A record pointing directly to the VPS; Cloudflare proxy bypassed for WebSocket compatibility).
   - OIDC SSO: Authenticates via `ratlogin` (`https://auth.daze.lol`, client ID `headscale`).
   - Reverse Proxy: Caddy providing TLS termination directly on ports 80/443.

2. **Host Enrollment & MagicDNS**:
   - `misty` and `halo` join the tailnet via `services.tailscale` targeting `https://head.daze.lol`.
   - MagicDNS manages private host resolution (`misty.daze.internal`, `halo.daze.internal`).

3. **Tailnet Proxying & Access Control**:
   - Halo's reverse proxy (`modules/caddy.nix`) forwards `video.daze.lol` over the Tailnet to Misty.
   - Media administration interfaces (Jellyfin, Servarr, Seerr, FileBrowser) stay strictly closed to external WAN traffic, accessible only via Tailnet IPs.


## Current Headscale Tailnet Status

The Headscale control plane is hosted on Raff VM `vista` at `https://head.daze.lol` (DNS-only), with public bootstrap IP `51.81.22.34`. Halo is enrolled at `100.64.0.1`; Vista is enrolled at `100.64.0.2`; Misty is enrolled at `100.64.0.4` (2026-10-06). Misty's `hosts/misty/configuration.nix` now sets `services.tailscale.enable = true`, and it was joined with a short-lived pre-auth key using `--accept-dns=false`.

Misty is reachable for administration over its assigned `100.64.0.4` tailnet address (the `192.168.1.174` LAN still serves the media interfaces). chi is not on the tailnet, so from chi reach tailnet peers through Misty: `ssh -J molly@192.168.1.174 molly@100.64.0.1` (halo) or `ssh -J molly@192.168.1.174 mollyw@100.64.0.2` (vista). The full enrollment and recovery runbook is maintained in [`halo-nixos/TAILNET.md`](../halo-nixos/TAILNET.md).
