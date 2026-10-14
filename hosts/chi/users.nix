# chi roster: mollyw is the sole human account on this laptop. (chi keeps the
# legacy `mollyw` login; halo and misty use `molly`.)
{pkgs, ...}: {
  users.users.mollyw = {
    isNormalUser = true;
    description = "Molly Wunderlich";
    shell = pkgs.zsh;
    # The input group lets the user gesture service read the internal touchscreen.
    extraGroups = ["input" "networkmanager" "wheel" "dialout"];
  };

  # Passwordless sudo is deliberate: this user administers the host and drives
  # non-interactive remote deploys (`nixos-rebuild --use-remote-sudo`). It does
  # make the account root-equivalent, so treat its SSH key accordingly.
  security.sudo.extraRules = [
    {
      users = ["mollyw"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
