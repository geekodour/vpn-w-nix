{ modulesPath, config, lib, pkgs, ... }: let
  pc_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgtcOFP7ZLkmkqpZhXf5YZ1+kFw9YEyYtyVpsRm0RgC";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/virtualisation/amazon-image.nix")
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ ena ];

  # We keep this access even if we have tailscale ssh for any case tailscale
  # daemon stops working
  users.users.root.openssh.authorizedKeys.keys = [pc_key];
  users.users.foo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "docker" ]; # Enable 'sudo' for the user
    initialPassword = "123";
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [pc_key];
  };
  home-manager.users.foo = import ./home.nix;
  programs.fish.enable = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  environment.systemPackages = with pkgs; [
    # base
    curl
    wget
    git
    gnumake

    # editors
    neovim
    vim

    # utils
    htop
    ripgrep
    fd
    jq

    # debugging
    file
    exiftool
    ethtool

    # misc
    which
    tree
    gnused
    gnutar
    gawk
    zstd

    # system call monitoring
    lsof # list open files

    # dev
    gcc11
    stdenv
    pkg-config

    # networking tools
    nethogs
    dig

    # ops
    dmidecode
    awscli2
    ssm-session-manager-plugin
    just
    ctop

    # db
    pgcli
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # docker aws combination
  # NOTE: This bugger had me going nuts because aws metadata services run in 169.254.169.254
  # see https://forums.docker.com/t/how-to-prevent-docker-from-creating-virtual-interface-on-wrong-private-network/124552/7
  # see https://github.com/NixOS/nixpkgs/issues/109389
  networking.dhcpcd.denyInterfaces = [ "veth*" ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
