{ pkgs, ... }: {
  # Assuming backup drive is xfs
  environment.systemPackages = with pkgs; [ xfsprogs ];

  systemd = {
    mounts = [{
      what = "/dev/disk/by-label/Backup";
      type = "xfs";
      where = "/mnt/backup";
    }];
    automounts = [{
      where = "/mnt/backup";
      automountConfig = { TimeoutIdleSec = 300; };
    }];
    sockets."restic-backup" = {
      listenStreams = [ "/run/restic-server.sock" ];
      socketConfig = { Service = "container@restic-server.service"; };
    };
    services."container@restic-server" = {
      after = [ "mnt-backup.automount" ];
      requires = [ "mnt-backup.automount" ];
    };
  };

  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:5022" = {
    extraConfig = "reverse_proxy unix//run/restic-server.sock";
  };

  containers."restic-server" = {
    autoStart = false;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.67.4";
    localAddress = "192.168.69.4";

    config = { ... }: {
      services.restic.server = {
        enable = true;
        listenAddress = "unix:/run/restic-server.sock";
        extraFlags = [ "--no-auth" ];
      };

      system.stateVersion = "25.05";
    };

    bindMounts = {
      "/run/restic-server.sock" = {
        hostPath = "/run/restic-server.sock";
        isReadOnly = false;
      };
      "/var/lib/restic" = {
        hostPath = "/mnt/backup";
        isReadOnly = false;
      };
    };
  };
}
