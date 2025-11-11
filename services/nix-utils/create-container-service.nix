{ id, name, internalPort, hostPort, containerConfig, dataMountPoint, secretsPath
, extraBindMounts, stateVersion, lib, ... }: {
  bindmountName = dataMountPoint ? name;

  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:${hostPort}" = {
    extraConfig = "reverse_proxy 192.168.67.100:${internalPort}";
  };
  networking.firewall.allowedTCPPorts = [ 8024 ];

  containers.${name} = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.67.${id}";
    localAddress = "192.168.69.${id}";

    config = { ... }:
      {
        networking.firewall.allowedTCPPorts = [ internalPort ];
      } // containerConfig;

    bindMounts = {
      "/run/secrets/${name}:idmap" =
        lib.mkIf secretsPath { hostPath = "/etc/nixos/auth/${secretsPath}"; };
      dataPath = {
        mountPoint = dataMountPoint;
        hostPath = "/data/${name}";
        isReadOnly = false;
      };
    } // extraBindMounts;

    system.stateVersion = stateVersion;
  };
}
