{ ... }: {
  fileSystems."/var/lib/private/wakapi" = {
    depends = [ "/data" ];
    device = "/data/wakapi";
    fsType = "none";
    options = [ "bind" ];
  };
  fileSystems."/run/secrets/wakapi" = {
    depends = [ "/data" ];
    device = "/etc/nixos/auth/wakapi";
    fsType = "none";
    options = [ "bind" ];
  };

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
      services.wakapi = {
        enable = true;
        passwordSaltFile = "/run/secrets/wakapi/password_pepper.env";
        database = {
          name = "/var/lib/wakapi/wakapi.db";
          dialect = "sqlite3";
        };
        settings = {
          server = { public_url = "https://pix.pug-squeaker.ts.net:3000"; };
          app = { leaderboard_enabled = false; };
          security = {
            allow_signup = false;
            disable_frontpage = true;
            insecure_cookies = false;
            trust_reverse_proxy_ips = [ "192.168.102.10" ];
          };
          db = {
            name = "/var/lib/wakapi";
          };
        };
      };
    };

    bindMounts = {
      "/run/secrets/wakapi:idmap" = {
        hostPath = "/etc/nixos/auth/wakapi";
      };
      "/var/lib/private/wakapi:idmap" = {
        hostPath = "/data/wakapi";
        isReadOnly = false;
      };
    };
  };
}
