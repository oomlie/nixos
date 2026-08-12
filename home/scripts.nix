{pkgs, ...}: let
  khalNextEvent = pkgs.writers.writePython3Bin "khal-next-event" {} ''
    import datetime
    import subprocess
    import sys

    KHAL = "${pkgs.khal}/bin/khal"
    KHAL_FORMAT = "{start-long} | {title}"
    # Must match longdatetimeformat in khal.nix
    START_FORMAT = "%Y %m %d %I:%M %p"


    def parse_start(value):
        try:
            return datetime.datetime.strptime(value, START_FORMAT)
        except ValueError:
            return None


    def relative(delta):
        if delta.days >= 1:
            return f"{delta.days}d {delta.seconds // 3600}h"
        if delta.seconds >= 3600:
            return f"{delta.seconds // 3600}h {(delta.seconds % 3600) // 60}m"
        if delta.seconds >= 60:
            return f"{delta.seconds // 60}m"
        return "now"


    def next_event():
        """Return (start, title) of the next event, or None."""
        try:
            output = subprocess.check_output(
                [KHAL, "list", "--format", KHAL_FORMAT, "now", "7d"],
                text=True,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            return None

        if not output.strip():
            return None

        now = datetime.datetime.now()
        upcoming = []
        for line in output.splitlines():
            if " | " not in line:
                continue
            start_part, title = line.split(" | ", 1)
            start = parse_start(start_part.strip())
            if start is None or start <= now:
                continue
            upcoming.append((start, title.strip()))

        if not upcoming:
            return None
        return min(upcoming, key=lambda item: item[0])


    def main():
        event = next_event()

        # --write-cache PATH: store "epoch<TAB>title" so cheap readers can
        # render the countdown without paying khal's ~1s Python startup
        if "--write-cache" in sys.argv:
            path = sys.argv[sys.argv.index("--write-cache") + 1]
            with open(path, "w", encoding="utf-8") as handle:
                if event is not None:
                    start, title = event
                    handle.write(f"{int(start.timestamp())}\t{title}")
            return

        if event is None:
            return
        start, title = event
        sys.stdout.write(f"{title} in {relative(start - datetime.datetime.now())}")


    if __name__ == "__main__":
        main()
  '';

  # Renders the cached next-event countdown without invoking khal
  khalNextEventRead = pkgs.writeShellScript "khal-next-event-read" ''
    cache="''${XDG_CACHE_HOME:-$HOME/.cache}/khal-next-event"
    if [ -f "$cache" ]; then
      IFS=$'\t' read -r epoch title < "$cache"
      [ -z "$epoch" ] && exit 0
      now=$(date +%s)
      d=$((epoch - now))
      if [ "$d" -lt 60 ]; then
        r="now"
      elif [ "$d" -lt 3600 ]; then
        r="$((d / 60))m"
      elif [ "$d" -lt 86400 ]; then
        r="$((d / 3600))h $((d % 3600 / 60))m"
      else
        r="$((d / 86400))d $((d % 86400 / 3600))h"
      fi
      printf '%s in %s' "$title" "$r"
    else
      # No cache yet (fresh boot): pay khal's startup once
      exec ${khalNextEvent}/bin/khal-next-event
    fi
  '';

  weatherDc = pkgs.writers.writePython3Bin "weather-dc" {} ''
    import sys
    import urllib.request


    def main():
        try:
            request = urllib.request.Request(
                "https://wttr.in/Washington+DC?format=%c+%t&m",
                headers={"User-Agent": "curl/8.0"},
            )
            with urllib.request.urlopen(request, timeout=10) as response:
                text = response.read().decode().strip()
            # wttr.in returns e.g. "⛅ +23°C"; strip the leading plus sign.
            text = text.replace("+", "", 1)
        except Exception:
            text = "— °C"

        sys.stdout.write(text)


    if __name__ == "__main__":
        main()
  '';
in {
  _module.args = {inherit khalNextEvent khalNextEventRead weatherDc;};
}
