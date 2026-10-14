_: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.0/8"
      "::1"
    ];
    jails.sshd = {
      settings = {
        enabled = true;
        maxretry = 5;
      };
    };
  };

  # Open ports:
  #   22   ssh
  #   80/443  Caddy (HTTP + automatic HTTPS)
  #   2965/29665  Reticulum AutoInterface (UDP)
  #   4242  Reticulum TCP
  networking.firewall = {
    allowedTCPPorts = [22 80 443 4242];
    allowedUDPPorts = [2965 29665];
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
}
