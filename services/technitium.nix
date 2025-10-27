{ lib, pkgs, ... }:
{
  fileSystems."/var/lib/private/technitium-dns-server" = {
      depends = [ "/data" ];
      device = "/data/technitium";
      fsType = "none";
      options = [ "bind" ];
  };

  environment.systemPackages = [ pkgs.libmsquic ];

  systemd.services.technitium-dns-server.serviceConfig = {
    WorkingDirectory = lib.mkForce null;
    BindPaths = lib.mkForce null;
  };
  services.technitium-dns-server = {
    enable = true;
    openFirewall = true;
    firewallUDPPorts = [ 53 853 ];
    firewallTCPPorts = [ 53 443 853 5380 ];
  };
}
