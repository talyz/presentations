let
  webserver =
    { config, pkgs, ... }:
    {
      services.nginx.enable = true;
      services.nginx.virtualHosts."example" = {
        listen = [{
          addr = "0.0.0.0";
          extraParameters = [ "proxy_protocol" ];
        }];
        locations."/" = {
          root = "${config.system.build.manual.manualHTML}/share/doc/nixos/";
        };
      };

      networking.firewall.allowedTCPPorts = [ 80 ];
    };

  load_balancer =
    { config, pkgs, ... }:
    {
      deployment.keys = {
        ssl_cert = {
          keyFile = /home/talyz/Projects/server-setup/secrets/ssl/wildcard_2019.certificate_private_key_bundle.pem;
          permissions = "0600";
        };
      };

      # Set up encrypted links to the web servers so we don't have to
      # manually set up TLS on them.
      deployment.encryptedLinksTo = [ "webserver1" "webserver2" ];

      services.haproxy.enable = true;
      services.haproxy.config = ''
        global
          # From https://ssl-config.mozilla.org/
          # Modern config as of Feb 2020 - update it from the link above!
          ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tlsv12 no-tls-tickets

          ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tlsv12 no-tls-tickets

        defaults
          mode http

       frontend public
          bind :443 ssl crt ${config.deployment.keys.ssl_cert.path} alpn h2,http/1.1

          # Redirect http -> https
          bind :80
          redirect scheme https code 301 if ! { ssl_fc }

          # HSTS (15768000 seconds = 6 months)
          http-response set-header Strict-Transport-Security max-age=15768000

          use_backend site

        backend site
          server webserver1 webserver1-encrypted:80 check send-proxy
          server webserver2 webserver2-encrypted:80 check send-proxy
      '';

      users.users.haproxy.extraGroups = [ "keys" ];

      networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
in
{
  webserver1 = webserver;
  webserver2 = webserver;
  inherit load_balancer;
}
