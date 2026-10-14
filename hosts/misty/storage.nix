# Disk layout for misty: 512 GB SSD (boot/root) plus two independent
# 12 TB data disks. No RAID and no encryption; neither data disk is a
# backup. Movies+music share one disk and TV the other so that download
# staging and the matching library are on the same filesystem, keeping
# hardlinks and instant moves working.
{
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SanDisk_SD8SB8U512G1001_174023800693";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      movies = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST12000DM0007-2GR116_ZJV0SB18";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/srv/movies";
              mountOptions = ["noatime"];
            };
          };
        };
      };

      tv = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST12000DM0007-2GR116_ZJV43VB9";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/srv/tv";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };
  };
}
