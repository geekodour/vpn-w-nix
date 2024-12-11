# NOTE: subnet router setup
#       For this useacse, we're running
#       tailscale in a subnet router setup. You could also
#       have the tailscale client on each machine and that'd have the more
#       tailscale mesh network thing
{ config, pkgs, lib, ... }: let

  # NOTE: Manually set the subnets
  #       Manually set the subnets you want this subnet router to advertise
  #       access to. Eg. You can  have rds and other internal workloads in
  #       private subnets.
  aws_vpc_private_subnets = "10.0.3.0/24,10.0.4.0/24";
in {

  networking.firewall = {
    allowedUDPPorts = [41641];
  };

  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    interfaceName = "tailscale0";
  };

  # oneshot job to authenticate to tailscale
  # this expects TAILSCALE_AUTH_KEY to be set via aws ssm params
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      # https://login.tailscale.com/admin/settings/keys
      # Usually you'd pick a single use key from the UI and it should work
      ${tailscale}/bin/tailscale up --advertise-routes=${aws_vpc_private_subnets} --accept-dns=false --auth-key $(${awscli2}/bin/aws ssm get-parameters --with-decryption --output text  --query "Parameters[0].Value"  --name TAILSCALE_AUTH_KEY)
    '';
  };

  # TODO: This is an optimization, this is not working as expected as of the
  #       moment. come back later
  #       https://tailscale.com/kb/1320/performance-best-practices
  # services.networkd-dispatcher = {
  #   enable = true;
  #   rules."enable-udp-gro-tailscale" = {
  #     onState = ["routable" "off"];
  #     script = ''
  #       #!${pkgs.runtimeShell}
  #       NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
  #       ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
  #       exit 0
  #     '';
  #   };
  # };
}
