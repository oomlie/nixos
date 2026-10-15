{pkgs, ...}: let
  # Keeps the fleet docs mirrored into the git-backed Context collection the agent can read, so the
  # agent sees README/NETWORK/AGENTS without being told. journal.md lives in the collection and is
  # hand-written, so this only ever touches the three mirrored files.
  #
  # Runs as a user service: the git token is in the login keyring (service=context-git), the same
  # entry created in the Context UI.
  askpass = pkgs.writeShellScript "context-git-askpass" ''
    case "$1" in
      Username*) echo x-access-token ;;
      Password*) secret-tool lookup service context-git user molly ;;
    esac
  '';
  sync = pkgs.writeShellApplication {
    name = "context-docs-sync";
    runtimeInputs = with pkgs; [git libsecret coreutils];
    text = ''
      set -euo pipefail
      remote="https://ab50bec72354666a941823793fef426a.artifacts.cloudflare.net/git/gatekeeper-context-collections/c481fb7b-acf9-46f9-9288-629f15853bc3.git"
      src="''${NIXOS_REPO:-$HOME/nixos}"
      cache="''${XDG_DATA_HOME:-$HOME/.local/share}/context-docs-sync/repo"

      export GIT_ASKPASS=${askpass}
      export GIT_TERMINAL_PROMPT=0
      secret-tool lookup service context-git user molly >/dev/null \
        || { echo "context-docs-sync: no git token in the keyring" >&2; exit 1; }

      if [ -d "$cache/.git" ]; then
        git -C "$cache" fetch -q origin main
        git -C "$cache" reset -q --hard origin/main
      else
        mkdir -p "$(dirname "$cache")"
        git clone -q "$remote" "$cache"
      fi
      git -C "$cache" config user.name molly
      git -C "$cache" config user.email molly@molly.computer

      for f in README.md NETWORK.md AGENTS.md; do
        cp "$src/$f" "$cache/$f"
      done

      if git -C "$cache" diff --quiet; then
        echo "context docs already current"
        exit 0
      fi
      git -C "$cache" add -A
      git -C "$cache" commit -q -m "sync fleet docs from oomlie/nixos"
      git -C "$cache" push -q origin main
      echo "context docs updated"
    '';
  };
in {
  home.packages = [sync];

  systemd.user.services.context-docs-sync = {
    Unit.Description = "Mirror the fleet docs into the Context collection";
    Service = {
      Type = "oneshot";
      ExecStart = "${sync}/bin/context-docs-sync";
    };
  };

  systemd.user.timers.context-docs-sync = {
    Unit.Description = "Mirror the fleet docs daily";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
