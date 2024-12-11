{ config, pkgs, lib, ... }:
let
  # generate:
  #
  # sudo su
  # cd /root
  # openvpn --genkey secret foo_client.key
  client-key = "/root/foo_client.key";
  domain = "54.81.202.222"; # could be a domain aswell if points
  vpn-dev = "tun0";
  port = 1194;
in {

  # services.openvpn.servers = {
  #   officeVPN = {
  #     autoStart = true;
  #     config = "config /root/nixos/openvpn/officeVPN.conf ";
  #     updateResolvConf = true; # maybe this line could fix it
  #   };
  # };

  # sudo systemctl start nat
  networking.nat = {
    enable = true;
    externalInterface = "ens5";
    internalInterfaces = [ vpn-dev ];
  };
  networking.firewall.trustedInterfaces = [ vpn-dev ];
  networking.firewall.allowedUDPPorts = [ port ];
  environment.systemPackages = [ pkgs.openvpn ]; # for key generation
  services.openvpn.servers.foo_server.config = ''
    dev ${vpn-dev}
    proto udp
    secret ${client-key}
    port ${toString port}
    ifconfig 10.0.2.10 10.0.2.11
    route-gateway 10.0.2.1

    cipher AES-256-CBC
    auth-nocache

    comp-lzo
    keepalive 10 60
    ping-timer-rem
    persist-tun
    persist-key
  '';

  environment.etc."openvpn/foo_client.ovpn" = {
    text = ''
      dev tun
      remote "${domain}"
      port ${toString port}
      redirect-gateway def1

      cipher AES-256-CBC
      auth-nocache

      comp-lzo
      keepalive 10 60
      resolv-retry infinite
      nobind
      persist-key
      persist-tun
      secret [inline]

    '';
    mode = "600";
  };

  system.activationScripts.openvpn-addkey = ''
    f="/etc/openvpn/foo_client.ovpn"
    if ! grep -q '<secret>' $f; then
      echo "appending secret key"
      echo "<secret>" >> $f
      cat ${client-key} >> $f
      echo "</secret>" >> $f
    fi
  '';
}
