# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ pkgs, home-manager, ... }:
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

in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      home-manager.nixosModules.default
      # <home-manager/nixos>
    ];
  nixpkgs.config =
    {
      allowBroken = true;
      allowUnfree = true;
    };

  # Use the GRUB 2 boot loader.
  boot.loader.grub =
    {

      splashImage = ./splash.png;
      enable = true;
      device = "/dev/sda";
    };
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  console.useXkbConfig = true; # use xkbOptions in tty.
  #};
  # nixpkgs.config.allowUnfree = true; 
  nix = {
    package = pkgs.nixFlakes;

    settings = {
      extra-experimental-features = [ "nix-command" "flakes" ];
    };
  };
  services = {
    dbus.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    openssh.enable = true;
    getty.autologinUser = "alberto";
    localtimed.enable = true;
    geoclue2.enable = true;
  };



  security.polkit.enable = true;
  users.users.alberto = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # home-manager.useUserPackages = true;
  home-manager.users.alberto = { config, pkgs, lib, ... }: {
    home.stateVersion = "23.05";
    # programs.neovim = {
    #   enable = true;
    #   defaultEditor = true;
    #   viAlias = true;
    #   vimAlias = true;
    #   vimdiffAlias = true;
    #   plugins = with pkgs.vimPlugins; [
    #     nvim-lspconfig
    #     nvim-treesitter.withAllGrammars
    #     plenary-nvim
    #     gruvbox-material
    #     mini-nvim
    #   ];
    # };
    services = {
      gammastep = { provider = "geoclue2"; enable = true; };
    };

    programs = {
      git = {
        enable = true;
        userName = "ZanovelloAlberto";
        userEmail = "zanovello2002@gmail.com";
      };

      foot = {
        enable = true;
        settings = {
          main = {
            term = "xterm-256color";

            font = "FiraCode Nerd Font Mono:style=Regular:size=13";
            dpi-aware = "yes";
          };
          mouse = {
            hide-when-typing = "yes";
          };
        };
      };
    };
    wayland.windowManager.sway = {
      enable = true;
      config = {
        keybindings =
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
            menu = config.wayland.windowManager.sway.config.menu;
          in
          lib.mkOptionDefault
            {
              # "${modifier}+Return" = "exec ${pkgs.foot}/bin/foot";
              # "${modifier}+Shift+q" = "kill";
              "${modifier}+u" = "workspace next";
              "${modifier}+p" = "${menu}";
              "${modifier}+o" = "pavucontrol";
              # "${modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_path | ${pkgs.dmenu}/bin/dmenu | ${pkgs.findutils}/bin/xargs swaymsg exec --";
            };

        input = {
          "*" = {
            xkb_layout = "us";
            xkb_options = "caps:swapescape";
            repeat_delay = "200";
            repeat_rate = "35";
          };
        };
        modifier = "Mod4";
        # Use kitty as default terminal
        terminal = "foot";
        startup = [
          # Launch Firefox on start
          # { command = "firefox"; }
        ];
      };
    };
    home.packages = with pkgs;[
      # firefox
      # foot
      tree
      neovim
      fish
      cargo
      pavucontrol
      clang
      zig
      fish
      unzip
      # google-chrome
      alacritty # gpu accelerated terminal
      dbus-sway-environment
      configure-gtk
      wayland
      xdg-utils # for opening default programs when clicking links
      glib # gsettings
      dracula-theme # gtk theme
      gnome3.adwaita-icon-theme # default gnome cursors
      swaylock
      nerdfonts
      swayidle
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      bemenu # wayland clone of dmenu
      mako # notification system developed by swaywm maintainer
      wdisplays # tool to configure displays
    ];
  };


  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


  # -------------------- SWAY
  environment.systemPackages = with pkgs; [
    git

  ];




  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # enable sway window manager
  programs = {
    fish = {
      enable = true;
      loginShellInit = "sway\n";
    };

    sway = {

      enable = true;
      wrapperFeatures.gtk = true;
    };
  };

  # -------------------------------------



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

