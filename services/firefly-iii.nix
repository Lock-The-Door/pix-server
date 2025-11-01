let fireflyUrl = "https://pix.pug-squeaker.ts.net:8024";
in { pkgs, ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8024" = {
    extraConfig = "php_fastcgi unix//run/container_firefly-iii/firefly-iii.sock";
  };
  networking.firewall.allowedTCPPorts = [ 8024 ];

  systemd.services.firefly-iii-socket = {
    description =
      "Prepare a socket directory in /run to mount to Firefly III owned by caddy";
    before = [ "containers@firefly-iii.service" ];
    wantedBy = [ "containers@firefly-iii.service" ];

    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "container_firefly-iii";
      RuntimeDirectoryMode = "611";
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };

  containers.firefly-iii = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.103.10";
    localAddress = "192.168.103.100";

    config = { ... }: {
      networking.firewall.allowedTCPPorts = [ 80 ];

      environment.defaultPackages = with pkgs; [ nmap ];

      services.firefly-iii = {
        enable = true;
        dataDir = "/var/lib/firefly-iii/app";
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
        enable = true;
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
      "/run/phpfpm:idmap" = {
        hostPath = "/run/container_firefly-iii";
        isReadOnly = false;
      };
      "/var/lib/private/firefly-iii:idmap" = {
        hostPath = "/data/firefly-iii";
        isReadOnly = false;
      };
    };
  };
}
