{ ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:3000" = {
    extraConfig = "reverse_proxy 192.168.102.100:3000";
  };
  networking.firewall.allowedTCPPorts = [ 3000 ];

  containers.wakapi = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.102.10";
    localAddress = "192.168.102.100";

    config = { ... }: {
      networking.firewall.allowedTCPPorts = [ 3000 ];
      services.wakapi = {
        enable = true;
        passwordSaltFile = "/run/secrets/wakapi/password_pepper.env";
        database = {
          name = "/var/lib/wakapi/wakapi.db";
          dialect = "sqlite3";
        };
        settings = {
          server = {
            listen_ipv6 = "::";
            public_url = "https://pix.pug-squeaker.ts.net:3000";
          };
          app = { leaderboard_enabled = false; };
          security = {
            allow_signup = false;
            disable_frontpage = true;
            insecure_cookies = false;
            trust_reverse_proxy_ips = "192.168.102.10";
          };
        };
      };

      system.stateVersion = "25.05";
    };

    bindMounts = {
      "/run/secrets/wakapi:idmap" = { hostPath = "/etc/nixos/auth/wakapi"; };
      "/var/lib/private/wakapi:idmap" = {
        hostPath = "/data/wakapi";
        isReadOnly = false;
      };
    };
  };
}
