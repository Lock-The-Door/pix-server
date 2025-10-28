{
  disko.devices = {
    disk = {
      primary = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/EFI";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # System mounts
                  "/rootfs" = {
                    mountOptions = [ "compress=lzo" "noatime" ];
                    mountpoint = "/";
                  };
                  "/nix" = {
                    mountOptions = [ "compress=lzo" "noatime" ];
                    mountpoint = "/nix";
                  };
                  # OS config mount
                  "/nixos" = {
                    mountOptions = [ "compress=lzo" ];
                    mountpoint = "/etc/nixos";
                  };
                  # Data mounts
                  "/home" = {
                    mountOptions = [ "compress=lzo" ];
                    mountpoint = "/home";
                  };
                  "/data" = {
                    mountOptions = [ "compress=lzo" ];
                    mountpoint = "/data";
                  };
                  "/data/tailscale" = { };
                  "/data/technitium" = { };
                  "/data/vikunja" = { };
                  "/data/vencloud" = { };
                  # Subvolume for the swapfile
                  "/swap" = {
                    mountpoint = "/.swap";
                    mountOptions = [ "compress=lzo" "noatime" ];
                    swap = { swapfile.size = "8G"; };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
