let fireflyUrl = "https://pix.pug-squeaker.ts.net:8024";
in { pkgs, ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8024" = {
    extraConfig = "reverse_proxy 192.168.103.100:80";
  };
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8025" = {
    extraConfig = "reverse_proxy 192.168.103.100:8080";
  };
  networking.firewall.allowedTCPPorts = [ 8024 ];

  containers.firefly-iii = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.103.10";
    localAddress = "192.168.103.100";

    config = { ... }: {
      networking.firewall.allowedTCPPorts = [ 80 8080 ];

      services.caddy = {
        enable = true;
        user = "nginx";
        group = "nginx";
        globalConfig = ''
          servers {
          	trusted_proxies static private_ranges
          }
        '';
        extraConfig = ''
          :8080 {
           	root * ${pkgs.firefly-iii}/public
            php_fastcgi ${config.services.phpfpm.pools.firefly-iii.socket} {
              capture_stderr
            }
            file_server
          }
        '';
      };

      services.nginx.virtualHosts."pix.pug-squeaker.ts.net:8025".

      services.firefly-iii = {
        enable = true;
        dataDir = "/var/lib/firefly-iii/app";
        virtualHost = "pix.pug-squeaker.ts.net:8025";
        enableNginx = true;
        poolConfig.settings."access.log" = /tmp/php-fpm.access.log;
        settings = {
          APP_ENV = "production";
          APP_URL = fireflyUrl;
          APP_KEY_FILE = "/run/secrets/firefly-iii";
          TZ = "America/Toronto";
          COOKIE_DOMAIN = "https://pix.pug-squeaker.ts.net:8024";
          COOKIE_SECURE = "true";
          ENABLE_EXTERNAL_MAP = "true";
          ENABLE_EXCHANGE_RATES = "true";
          ENABLE_EXTERNAL_RATES = "true";
          MAP_DEFAULT_LAT = "43.6425";
          MAP_DEFAULT_LONG = "-79.387222";
          MAP_DEFAULT_ZOOM = "6";
          VALID_URL_PROTOCOLS = "http, https, mailto";
        };
      };
      systemd.services.firefly-iii.serviceConfig.StateDirectory =
        "firefly-iii/app";
      services.firefly-iii-data-importer = {
        enable = false;
        # group = "firefly-iii";
        dataDir = "/var/lib/firefly-iii/importer";
        settings = { FIREFLY_III_URL = fireflyUrl; };
      };
      systemd.services.firefly-iii-data-importer.serviceConfig.StateDirectory =
        "firefly-iii/importer";

      system.stateVersion = "25.05";
    };

    bindMounts = {
      "/run/secrets/firefly-iii:idmap" = {
        hostPath = "/etc/nixos/auth/firefly-iii";
      };
      "/var/lib/firefly-iii:idmap" = {
        hostPath = "/data/firefly-iii";
        isReadOnly = false;
      };
    };
  };
}
