{ lib, ... }:
{
  fileSystems."/var/lib/private/technitium-dns-server" = {
      depends = [ "/data" ];
      device = "/data/technitium";
      fsType = "none";
      options = [ "bind" ];
  };

  systemd.services.technitium-dns-server.serviceConfig = {
    WorkingDirectory = lib.mkForce null;
    BindPaths = lib.mkForce null;
  };
  services.technitium-dns-server = {
    enable = true;
    openFirewall = true;
    firewallTCPPorts = [ 53 443 853 53443 ];
  };
}
