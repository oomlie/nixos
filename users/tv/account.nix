# TV kiosk account (misty only). The cage session itself lives in
# hosts/misty/configuration.nix.
{
  users.users.tv = {
    isNormalUser = true;
    uid = 1001;
    description = "Misty TV kiosk";
    group = "tv";
    extraGroups = ["video" "render"];
  };
  users.groups.tv = {gid = 990;};
}
