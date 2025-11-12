{ pkgs, ... }: {
  services.caddy.virtualHosts."https://pix.pug-squeaker.ts.net:22300" = {
    extraConfig = "reverse_proxy 127.67.5.1";
  };

  users.users."joplin-server" = {
    group = "joplin-server";
    isSystemUser = true;
    home = "/data/joplin-server";
  };
  users.groups."joplin-server" = { };

  virtualisation.oci-containers.containers."joplin-server" = {
    preRunExtraOptions = [ "--runtime" "${pkgs.crun}/bin/crun" ];
    podman.user = "joplin-server";

    image = "docker.io/joplin/server:3.4.3";
    ports = [ "127.67.5.1::22300" ];
    environment = {
      "APP_BASE_URL" = "https://pix.pug-squeaker.ts.net:22300";
      "SQLITE_DATABASE" = "/data/joplin-server.sqlite";
      "STORAGE_SERVER" = "Type=Filesystem; Path=/data/files";
    };
    volumes = [ "/data/joplin-server:/data" ];
  };
}
