{ ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8012" = {
    extraConfig = "reverse_proxy 192.168.101.100:8080";
  };
  networking.firewall.allowedTCPPorts = [ 8012 ];

  containers.vencloud = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.101.10";
    localAddress = "192.168.101.100";

    config = { ... }: {
      services.vencord = {
        enable = true;
        allowedUsers = [ 374284798820352000 ];
        proxyHeader = "X-Forwarded-For";
        environmentFiles = [ "/etc/nixos/auth/vencloud.env" ];
      };

      services.redis = {
        enable = true;
        save = [ [ 300 1 ] [ 60 10 ] ];
      };
    };
  };
}
