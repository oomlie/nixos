_: {
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8096;
    allowedHosts = "dash.daze.lol";

    settings = {
      title = "daze.lol";
      description = "Halo services";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      iconStyle = "theme";
      statusStyle = "dot";
      target = "_blank";
      hideVersion = true;
      disableIndexing = true;
      fullWidth = true;
      layout = [
        {
          Community = {
            style = "row";
            columns = 4;
          };
        }
        {
          Dev = {
            style = "row";
            columns = 4;
          };
        }
        {
          Infrastructure = {
            style = "row";
            columns = 4;
          };
        }
        {
          "Media & Publishing" = {
            style = "row";
            columns = 4;
          };
        }
      ];
    };

    widgets = [
      {
        resources = {
          label = "halo";
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
        };
      }
      {
        search = {
          provider = "custom";
          url = "https://search.daze.lol/search?q=";
          target = "_blank";
        };
      }
    ];

    services = [
      {
        Community = [
          {
            "Account Requests" = {
              icon = "mdi-account-plus";
              href = "https://requests.daze.lol/";
              description = "request a shell account";
            };
          }
          {
            Tasks = {
              icon = "mdi-checkbox-marked-circle-auto-outline";
              href = "https://tasks.daze.lol/";
              description = "Vikunja task management";
            };
          }
          {
            IRC = {
              icon = "mdi-forum";
              href = "https://irc.daze.lol/";
              description = "soju and gamja";
            };
          }
          {
            Search = {
              icon = "mdi-magnify";
              href = "https://search.daze.lol/";
              description = "SearXNG metasearch";
            };
          }
        ];
      }
      {
        Dev = [
          {
            Code = {
              icon = "mdi-source-repository";
              href = "https://code.daze.lol/";
              description = "Forgejo git hosting";
            };
          }
          {
            Chat = {
              icon = "mdi-robot";
              href = "https://chat.daze.lol/";
              description = "Open WebUI";
            };
          }
          {
            Knot = {
              icon = "mdi-source-branch";
              href = "https://knot.daze.lol/";
              description = "Tangled git server";
            };
          }
          {
            Spindle = {
              icon = "mdi-hammer-wrench";
              href = "https://spindle.daze.lol/";
              description = "Tangled CI runner";
            };
          }
        ];
      }
      {
        Infrastructure = [
          {
            "PDS Operator" = {
              icon = "mdi-shield-account";
              href = "https://pds-admin.daze.lol/";
              description = "Tranquil administration";
            };
          }
          {
            Hold = {
              icon = "mdi-package-variant-closed";
              href = "https://hold.daze.lol/";
              description = "ATCR container registry";
            };
          }
          {
            Route = {
              icon = "mdi-routes";
              href = "https://route.daze.lol/";
              description = "AI model gateway";
            };
          }
          {
            PDS = {
              icon = "mdi-at";
              href = "https://pds.daze.lol/";
              description = "ATProto personal data server";
            };
          }
        ];
      }
      {
        "Media & Publishing" = [
          {
            Music = {
              icon = "mdi-music";
              href = "https://music.daze.lol/";
              description = "Navidrome music library";
            };
          }
          {
            Game = {
              icon = "mdi-gamepad-variant";
              href = "https://game.daze.lol/";
              description = "RomM ROM library";
            };
          }
          {
            Pubnix = {
              icon = "mdi-console";
              href = "https://tilde.daze.lol/";
              description = "shells and member sites";
            };
          }
          {
            Paste = {
              icon = "mdi-content-paste";
              href = "https://paste.daze.lol/";
              description = "Microbin paste service";
            };
          }
          {
            Planet = {
              icon = "mdi-rss";
              href = "https://planet.daze.lol/";
              description = "member feed aggregator";
            };
          }
        ];
      }
    ];
  };

  systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";
}
