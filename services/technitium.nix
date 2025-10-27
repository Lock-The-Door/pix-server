{ ... }:
{
  services.technitium-dns-server = {
    enable = true;
    openFirewall = true;
    firewallTCPPorts = [ 53 443 853 53443 ];
  };
  fileSystems."/var/lib/technitium-dns-server" = {
      depends = [ "/data" ];
      device = "/data/technitium";
      fsType = "none";
      options = [ "bind" ];
  };
}
