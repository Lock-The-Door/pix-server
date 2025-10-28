{ pkgs, vencloud, ... }: {
  nixpkgs.overlays =  [
    (final: prev: {
      vencloud = vencloud.packages.${final.system}.default;
    })
  ];

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
      imports = [ vencloud.nixosModules.vencloud ];
      nixpkgs.pkgs = pkgs;

      networking.firewall.allowedTCPPorts = [ 8080 ];
      services.vencloud = {
        enable = true;
        allowedUsers = [ 374284798820352000 ];
        proxyHeader = "X-Forwarded-For";
        environmentFiles = [ "/run/secrets/vencloud.env" ];
      };

      services.redis.servers."" = {
        enable = true;
        save = [ [ 300 1 ] [ 60 10 ] ];
        unixSocket = null;
      };

      system.stateVersion = "25.05";
    };

    bindMounts = {
      "/run/secrets/vencloud.env:idmap" = {
        hostPath = "/etc/nixos/auth/vencloud.env";
      };

    };
  };
}
