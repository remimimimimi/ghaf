# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# !!! To utilize this partition scheme, the disk size must be >252G !!!
#
# This partition scheme contains three common partitions and two ZFS pools.
# First LVM pool occupies 250G and second one occupies the rest of the disk space.
# Some paritions are duplicated for the future AB SWupdate implementation.
#
# First three partitions are related to the boot process:
# - boot : Bootloader partition
# - ESP-A : (500M) Kernel and initrd
# - ESP-B : (500M)
#
# First ZFS pool contains next partitions:
# - root-A : (50G) Root FS
# - root-B : (50G)
# - vm-storage-A : (30G) Possible standalone pre-built VM images are stored here
# - vm-storage-B : (30G)
# - reserved-A : (10G) Reserved partition, no use
# - reserved-B : (10G)
# - gp-storage : (50G) General purpose storage for some common insecure cases
# - recovery : (rest of the ZFS pool) Recovery factory image is stored here
#
# Second ZFS pool is dedicated for Storage VM completely.
_: {
  networking.hostId = "8425e349";
  # A lot of memory required for some unknown reason
  disko.memSize = 4096;
  disko.extraRootModules = ["zfs"];
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp_a = {
            name = "ESP_A";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
                "nofail"
              ];
            };
          };
          esp_b = {
            name = "ESP_B";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountOptions = [
                "umask=0077"
                "nofail"
              ];
            };
          };
          root_a = {
            size = "30G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
          root_b = {
            size = "30G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
          zfs_1 = {
            size = "150G";
            content = {
              type = "zfs";
              pool = "zroot_1";
            };
          };
          # ZFS pool that is going to be passed to the Storage VM
          zfs_2 = {
            content = {
              type = "zfs";
              pool = "zroot_2";
            };
          };
        };
      };
    };
    zpool = {
      zroot_1 = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
        };
        datasets = {
          "vm_storage_a" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/vm_storage";
              quota = "30G";
            };
          };
          "reserved_a" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              quota = "10G";
            };
          };
          "vm_storage_b" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              quota = "30G";
            };
          };
          "reserved_b" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              quota = "10G";
            };
          };
          "gp_storage" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/gp_storage";
              quota = "50G";
            };
          };
          "recovery" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
            };
          };
        };
      };
      zroot_2 = {
        # Dedicated partition for StorageVM
        type = "zpool";
        mountpoint = "/storagevm";
        rootFsOptions = {
          canmount = "off";
        };
      };
    };
  };
}
