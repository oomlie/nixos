# misty roster: which people have accounts on this host, and their host-specific
# groups and SSH keys. Accounts are defined once under users/<person>/.
_: let
  keys = import ../../keys.nix;
in {
  imports = [
    ../../users/molly/account.nix
    ../../users/alys/account.nix
    ../../users/tv/account.nix
    ../../users/jade/account.nix
  ];

  users.users.molly.extraGroups = ["wheel" "video" "render" "media"];
  users.users.molly.openssh.authorizedKeys.keys = [
    keys.molly
    keys.mica
    keys.jade
  ];
}
