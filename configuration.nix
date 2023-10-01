# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ inputs
  # , outputs
  # , lib
, config
, pkgs
, ...
}:
let
  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts  
  # some user services to make sure they have the correct environment variables
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
  user = "alberto";
  i2c = config.boot.kernelPackages.callPackage ./modules/driver/i2c.nix { };
  # train_keep = pkgs.writeScriptBin "train_keep" ''
  # '';
  # droidcam = config.boot.kernelPackages.callPackage ./pkgs/droidcam.nix { };
  # pkgs.config.allowUnfree = true;
  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema gtk-theme 'Dracula'
      '';
  };

  # makeCfg = path: { ".config/${path}".source = ./config/${path}; };
  timer = ./pkgs/timer.nix;

in
{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      # inputs.doom-emacs.hmModule
    ];

  nix = {
    package = pkgs.nixFlakes;
    settings.auto-optimise-store = true;
    registry = {
      mytemp.to = {
        owner = "ZanovelloAlberto";
        repo = "templates";
        type = "github";
      };

      # ddd.to = {
      #   owner = "NixOs";
      #   repo = "nixpkgs";
      #   rev = "nixos-23.05";
      #   type = "github";
      # };
      # mytemp = "https://github.com/ZanovelloAlberto/templates.git";
    };

    settings = {
      sandbox = "relaxed";
      extra-experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs.config =
    {
      # allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      #   "google-chrome"
      #   "discord"
      # ];
      allowBroken = true;
      allowUnfree = true;
    };

  # Use the GRUB 2 boot loader.
  boot = {
    #   kernelPatches = [ {
    # name = "pca9685";
    # patch = null;
    # extraConfig = ''
    #     CONFIG_SYSFS y
    #     CONFIG_PWM_PCA9685=m
    #    '';
    #    # CONFIG_PWM_PCA9685
    # } ];
    # kernelParams = "CONFIG_PWM_PCA9685=y";
    kernelModules = [ "i2c_dev" "pwm" ];
    extraModulePackages = [ i2c ];
    loader.grub =
      {
        splashImage = ./splash.png;
        enable = true;
        device = "/dev/sda";
      };
  };

  console.useXkbConfig = true; # use xkbOptions in tty.

  services = {
    udev = {
      packages = [ pkgs.qmk-udev-rules ];
    };
    emacs = {
      enable = true;
    };
    dbus.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    openssh.enable = true;
    getty.autologinUser = user;
    localtimed.enable = true;
    geoclue2.enable = true;
  };

  security.polkit.enable = true;
  users.users.alberto = {

    isNormalUser = true;
    shell = pkgs.bash;
    extraGroups = [ "media" "dialout" "wheel" "adbusers" ]; # Enable ‘sudo’ for the user.
  };

  # home-manager.useUserPackages = true;
  home-manager.users.${user} = import ./modules/home-manager;

  environment = {
    systemPackages = with pkgs; [
      git
      google-chrome
      sysdig
      vscode
      # discord
      # obs-studio
      i2c-tools
    ];
    interactiveShellInit = ''
      alias open='xdg-open'
    '';
    # extraOutputsToInstall = ["dev"];
    variables.C_INCLUDE_PATH = "${pkgs.i2c-tools}/include";
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };

  # enable sway window manager
  programs = {
    sysdig.enable = true;
    adb.enable = true;
    # fish = {
    #   enable = true;
    #   loginShellInit = "sway\n";
    # };
    bash = {
      loginShellInit = "sway\n";
    };

    sway = {

      enable = true;
      wrapperFeatures.gtk = true;
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
