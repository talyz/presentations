{
  webserver =
    { config, pkgs, resources, nodes, ... }:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 128;
      deployment.virtualbox.vcpu = 1;

      services.nginx.enable = true;
      services.nginx.virtualHosts."example" = {
        locations."/" = {
          root = "${config.system.build.manual.manualHTML}/share/doc/nixos/";
        };
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
}
