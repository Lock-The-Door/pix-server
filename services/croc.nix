{ config, pkgs, lib, ... }:
let cfg = config.services.croc;
in {
  services.croc = {
    enable = true;
    pass = "";
    openFirewall = true;
  };

  systemd.services.croc.serviceConfig.ExecStart = lib.mkForce
    "${pkgs.croc}/bin/croc ${
      lib.optionalString (cfg.pass != "") "--pass '${cfg.pass}'"
    } ${lib.optionalString cfg.debug "--debug"} relay --ports ${
      lib.concatMapStringsSep "," toString cfg.ports
    }";
}
