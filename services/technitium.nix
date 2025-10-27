{ lib, pkgs, ... }:
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
  systemd.services.technitium-dns-server.environment.LD_LIBRARY_PATH = "${pkgs.libmsquic.out}/lib";
  services.technitium-dns-server = {
    enable = true;
    openFirewall = true;
    firewallUDPPorts = [ 53 853 ];
    firewallTCPPorts = [ 53 443 853 5380 53443 ];
  };
}
