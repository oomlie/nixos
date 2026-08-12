{khalNextEvent, ...}: let
  timezone = "America/New_York";
in {
  # Local calendar storage for khal
  home.file.".local/share/calendars/personal/.keep".text = "";

  xdg.configFile."khal/config".text = ''
    [calendars]
    [[personal]]
    path = ~/.local/share/calendars/personal
    color = dark blue

    [locale]
    timeformat = %I:%M %p
    dateformat = %m %d
    longdateformat = %Y %m %d
    datetimeformat = %m %d %I:%M %p
    # Must match START_FORMAT in scripts.nix
    longdatetimeformat = %Y %m %d %I:%M %p
    local_timezone = ${timezone}
    default_timezone = ${timezone}
    firstweekday = 6

    [default]
    default_calendar = personal
    highlight_event_days = true
    timedelta = 7d

    [view]
    theme = dark
    dynamic_days = true
  '';

  # Refresh the khal next-event cache for the bar every 5 minutes
  systemd.user.services.khal-next-event = {
    Unit.Description = "Refresh khal next-event cache for the bar";
    Service = {
      Type = "oneshot";
      ExecStart = "${khalNextEvent}/bin/khal-next-event --write-cache %C/khal-next-event";
    };
  };
  systemd.user.timers.khal-next-event = {
    Unit.Description = "Refresh khal next-event cache for the bar";
    Timer = {
      OnActiveSec = "1min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
