{ lib, ... }: {
	services.croc = {
		enable = true;
		pass = "";
		openFirewall = true;
	};

	systemd.services.croc.serviceConfig.ExecStart = "${pkgs.croc}/bin/croc ${lib.optionalString (services.croc.pass != "") "--pass '${services.croc.pass}'"} ${lib.optionalString services.croc.debug "--debug"} relay --ports ${
          lib.concatMapStringsSep "," toString services.croc.ports
        }";
}
