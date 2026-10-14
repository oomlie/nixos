# Jade (misty only): standalone niri agent account. The service and secrets
# live in hosts/misty/jade.nix.
{pkgs, ...}: {
  users.users.jade = {
    isNormalUser = true;
    uid = 1003;
    group = "jade";
    home = "/var/lib/jade/home";
    createHome = true;
    shell = pkgs.bash;
  };
  users.groups.jade = {gid = 989;};

  # Parity with Mica's container (which runs as a NOPASSWD-sudo user).
  security.sudo.extraRules = [
    {
      users = ["jade"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
