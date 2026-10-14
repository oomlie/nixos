# Installer ISO for the misty media server. Boots to a shell with
# key-only SSH; the disk layout is applied manually with disko after
# confirming /dev/disk/by-id paths on the real hardware.
{
  modulesPath,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "misty-installer";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  users.users.root.openssh.authorizedKeys.keys = [(import ../keys.nix).molly];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  systemd.services.sshd.wantedBy = ["multi-user.target"];

  environment.systemPackages = with pkgs;
    [
      git
      sops
      age
      smartmontools
      nvme-cli
      parted
      jq
    ]
    ++ [inputs.disko.packages.${pkgs.system}.disko];

  image.baseName = lib.mkForce "misty-installer";
}
