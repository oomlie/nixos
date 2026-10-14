# halo roster: which people have accounts on this host, and their host-specific
# groups. The account itself is defined once under users/<person>/.
{
  imports = [../../users/molly/account.nix];

  users.users.molly.extraGroups = ["networkmanager" "wheel" "video" "render" "docker" "dialout"];
}
