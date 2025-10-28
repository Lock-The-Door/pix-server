{ ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:3456" = {
    extraConfig = "reverse_proxy 192.168.100.11:3456";
  };
  networking.firewall.allowedTCPPorts = [ 3456 ];

  containers.vikunja = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.100";

    config = { config, pkgs, ... }: {
      networking.firewall = { allowedTCPPorts = [ 3456 ]; };

      systemd.services.generate-typesense-key = {
        requiredBy = [ "typesense.service" ];
        before = [ "typesense.service" ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          StateDirectory = "typesense-key";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          key="$(${pkgs.pwgen}/bin/pwgen -s 32 1)"
          touch "/var/lib/typesense-key/typesense.key"
          ${pkgs.coreutils}/bin/chmod 600 "/var/lib/typesense-key/typesense.key"
          printf '%s' "$key" > "/var/lib/typesense-key/typesense.key"

          touch "/var/lib/typesense-key/typesense.env"
          ${pkgs.coreutils}/bin/chmod 600 "/var/lib/typesense-key/typesense.env"
          ${pkgs.coreutils}/bin/cat <(printf "TYPESENSE_API_KEY=") "/var/lib/typesense-key/typesense.key" > "/var/lib/typesense-key/typesense.env"
        '';
      };

      systemd.services.copy-typesense-key = {
        requires = [ "generate-typesense-key.service" ];
        after = [ "generate-typesense-key.service" ];
        wantedBy = [ "vikunja.service" ];
        before = [ "vikunja.service" ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          StateDirectory = "typesense-key";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          touch "/var/lib/typesense-key/vikunja.env"
          ${pkgs.coreutils}/bin/chmod 600 "/var/lib/typesense-key/vikunja.env"
          ${pkgs.coreutils}/bin/cat <(printf "VIKUNJA_TYPESENSE_APIKEY=") "/var/lib/typesense-key/typesense.key" > "/var/lib/typesense-key/vikunja.env"
          ${pkgs.coreutils}/bin/cp /var/lib/typesense-key/typesense.key /etc/typesense/api.key
        '';
      };

      services.typesense = {
        enable = false;
        #environmentFiles = [ "/var/lib/typesense-key/typesense.env" ];
        settings.server.api-address = "127.0.0.1";
      };

      services.vikunja = {
        enable = true;
        frontendScheme = "https";
        frontendHostname = "pix.pug-squeaker.ts.net";
        environmentFiles = [ "/var/lib/typesense-key/vikunja.env" ];
        settings = {
          cors = {
            enable = true;
            origins = [ "https://pix-pug-squeaker.ts.net:3456" ];
            maxage = 0;
          };
          typesense = {
            enable = false;
            url = "http://127.0.0.1:8108";
          };
        };
      };
    };

    bindMounts = {
      "/var/lib/private/vikunja:idmap" = {
        hostPath = "/data/vikunja";
        isReadOnly = false;
      };
      #         "/var/lib/typesense:idmap" = {
      #           hostPath = "/var/tmp/vikunja-typesense";
      #         };
    };
  };
}
