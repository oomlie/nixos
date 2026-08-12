{
  config,
  pkgs,
  ...
}: let
  niri = "${config.programs.niri.package}/bin/niri";
  touchscreen = "/dev/input/by-path/pci-0000:00:15.0-platform-i2c_designware.0-event";
  tabletGestures = pkgs.writeShellScript "tablet-gestures" ''
    set -eu

    lisgd_pid=""
    sensor_pid=""
    sensor_fifo="''${XDG_RUNTIME_DIR:-/tmp}/tablet-gestures-$$.fifo"

    cleanup() {
      if [ -n "$lisgd_pid" ]; then
        kill "$lisgd_pid" 2>/dev/null || true
        wait "$lisgd_pid" 2>/dev/null || true
      fi
      if [ -n "$sensor_pid" ]; then
        kill "$sensor_pid" 2>/dev/null || true
        wait "$sensor_pid" 2>/dev/null || true
      fi
      rm -f "$sensor_fifo"
    }

    start_lisgd() {
      case "$1" in
        normal) orientation=0 ;;
        right-up) orientation=1 ;;
        bottom-up) orientation=2 ;;
        left-up) orientation=3 ;;
        *) return ;;
      esac

      if [ -n "$lisgd_pid" ]; then
        kill "$lisgd_pid" 2>/dev/null || true
        wait "$lisgd_pid" 2>/dev/null || true
      fi
      ${pkgs.lisgd}/bin/lisgd \
        -d ${touchscreen} \
        -o "$orientation" \
        -t 120 \
        -m 900 \
        -g "2,LR,L,*,R,${niri} msg action focus-column-left" \
        -g "2,RL,R,*,R,${niri} msg action focus-column-right" \
        -g "2,DU,B,*,R,${niri} msg action toggle-overview" &
      lisgd_pid=$!
    }

    trap cleanup EXIT INT TERM

    mkfifo "$sensor_fifo"
    ${pkgs.iio-sensor-proxy}/bin/monitor-sensor --accel >"$sensor_fifo" &
    sensor_pid=$!

    while IFS= read -r line; do
      case "$line" in
        *"orientation: normal"*|*"orientation changed: normal") start_lisgd normal ;;
        *"orientation: right-up"*|*"orientation changed: right-up") start_lisgd right-up ;;
        *"orientation: bottom-up"*|*"orientation changed: bottom-up") start_lisgd bottom-up ;;
        *"orientation: left-up"*|*"orientation changed: left-up") start_lisgd left-up ;;
      esac
    done <"$sensor_fifo"

    exit 1
  '';
in {
  home.packages = [
    pkgs.lisgd
    pkgs.wvkbd
  ];

  systemd.user.services = {
    tablet-keyboard = {
      Unit = {
        Description = "Framework tablet on-screen keyboard";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden -H 480 -L 360 --fn '${config.stylix.fonts.monospace.name} 20'";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    tablet-gestures = {
      Unit = {
        Description = "Rotation-aware Framework touchscreen edge gestures";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = tabletGestures;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
