{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ./common/base.nix
    # ./tailscale/tailscale.nix
    # ./openvpn/openvpn.nix
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6..conf.all.forwarding" = 1;

  # NOTE: This should not be updated once the system is initially setup, you can
  #       update the flake file to get the latest packages. This is needed for
  #       backwards compatibility.
  system.stateVersion = "24.05";
  home-manager.users.foo.home.stateVersion = "24.05";
}
