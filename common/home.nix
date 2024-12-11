{ config, pkgs, lib, ... }:
let h = "/home/foo";
in {
  home.homeDirectory = h;
  home.sessionVariables = {
    XDG_CACHE_HOME = "${h}/.cache";
    XDG_CONFIG_HOME = "${h}/.config";
    XDG_DATA_HOME = "${h}/.local/share";
    XDG_STATE_HOME = "${h}/.local/state";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
    EDITOR = "nvim";
  };

  programs.direnv = {
    enable = true;
    nix-direnv = { enable = true; };
  };

  # packages that should be installed to the user profile.
  home.packages = with pkgs; [
    tmux
  ];

  # Let home Manager install and manage itself
  programs.home-manager.enable = true;
}
