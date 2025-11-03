{ pkgs, ... }: {
  # Assuming backup drive is xfs
  environment.systemPackages = with pkgs; [ xfsprogs ];

  systemd = {
    mounts = [{
      what = "/dev/disk/by-label/Backup";
      type = "xfs";
      name = "backup.mount";
      where = "/mnt/backup";
    }];
    automounts = [{
      name = "backup.automount";
      where = "/mnt/backup";
      automountConfig = { TimeoutIdleSec = 300; };
    }];
    sockets."restic-backup" = {
      listenStreams = [ "/run/restic-server.sock" ];
      socketConfig = { Service = "container@restic-server"; };
    };
    services."container@restic-server" = {
      after = "backup.automount";
      requires = "backup.automount";
    };
  };

  containers."restic-server" = {
    autoStart = false;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.104.10";
    localAddress = "192.168.104.100";

    config = { ... }: {
      services.restic.server = {
        enable = true;
        listenAddress = "unix:/run/restic-server.sock";
        extraFlags = "--no-auth";
      };
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
