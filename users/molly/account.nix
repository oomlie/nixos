# Molly's account, shared by every host that includes this module.
# Host rosters add the per-host groups, shell, and SSH keys.
{lib, ...}: {
  users.users.molly = {
    isNormalUser = true;
    uid = 1000;
    description = lib.mkDefault "molly";
  };

  # Molly administers every host she is on.
  security.sudo.extraRules = [
    {
      users = ["molly"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
