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
  i2c = config.boot.kernelPackages.callPackage ./pkgs/i2c_341.nix { };
  droidcam = config.boot.kernelPackages.callPackage ./pkgs/droidcam.nix { };
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
  hideXdg = {
    name = "deleted";
    exec = "echo deleted";
    noDisplay = true;
  };
  deletexdg = list: builtins.listToAttrs
    ((x: builtins.map
      (i: {
        name = i;
        value = hideXdg;
        # {
        #         name = i;
        #         exec = i;
        #         noDisplay = true;
        #       };
      })
      x)
      list);
  makeCfg = path: { ".config/${path}".source = ./config/${path}; };

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

    settings = {
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
    extraModulePackages = [ i2c droidcam ];
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
    extraGroups = [ "media" "dialout" "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # home-manager.useUserPackages = true;
  home-manager.users.${user} = { config, pkgs, lib, ... }: {
    imports = [ inputs.doom-emacs.hmModule ];
    home = {
      sessionPath = [ "/home/${user}/.config/emacs/bin/" ];
      stateVersion = "23.05";
      username = user;
      homeDirectory = "/home/${user}";
      # file = makeCfg "doom"; #// makeCfg "rootbar";
    };

    xdg =
      {
        desktopEntries = {

          # discord = {
          #   name = "Discord";
          #   exec = "discord";
          #   noDisplay = true;
          # };
          # emacs = {
          #   name = "emacs";
          #   exec = "emacs";
          #   noDisplay = true;
          # };
          # "org.codeberg.dnkl.foot-server", "org.codeberg.dnkl.foot-server" = {
          #   name = "poot";
          #   exec = "poot";
          #   noDisplay = true;
          # };
          # firefox = {
          #   noDisplay = true;
          #   name = "firefox";
          # };
        } // (deletexdg [
          # "discord"
          "emacs"
          "org.codeberg.dnkl.foot-server"
          "org.codeberg.dnkl.foot"
          "umpv"
          "gammastep-indicator"
        ]);
      };
    services = {
      gammastep = {
        provider = "geoclue2";
        enable = true;
        # lower is warmer
        temperature = { night = 1500; };
      };

    };

    programs = {


helix = {
  enable = true;

settings = {
  theme = "adwaita-dark";
  editor = {
    line-number = "relative";
    lsp.display-messages = true;
  };
  keys.normal = {
    space.space = "file_picker";
    space.f = ":fmt";
    space.w = ":w";
    space.q = ":q";
    space.t = ":run-shell-command foot";
    space.v = ":run-shell-command nix-shell --run foot";
    "C-j" = ["move_visual_line_down" "move_visual_line_down""move_visual_line_down"];
    "C-k" = ["move_visual_line_up" "move_visual_line_up""move_visual_line_up"];
    esc = [ "collapse_selection" "keep_primary_selection" ];
  };
};
  languages = {language = [{
    name = "rust";
    auto-format = false;
  }];};
   
  
};

      doom-emacs = {
        enable = true;
        doomPrivateDir = ./config/doom; # Directory containing the config.el, init.el
      };
      tiny = {
        enable = true;

        settings = {
          servers = [
            {
              addr = "irc.libera.chat";
              port = 6697;
              tls = true;
              realname = "Alberto Zanovello";
              nicks = [ "Alberto" "ll" ];
            }
            # {
            #   addr = "chat.freenode.net";
            # }
          ];
          defaults = {
            nicks = [ "Alberto" "ll" ];
            realname = "vola";
            join = [ "#go-nuts" "#rust" ];
            tls = true;
          };
        };
      };
      eww = {
        # enable = true;
        configDir = ./config/eww;
      };

      git = {
        enable = true;
        userName = "ZanovelloAlberto";
        userEmail = "zanovello2002@gmail.com";
      };

      fuzzel =
        {
          enable = true;
          # package = config.lib.test.mkStubPackage { };

          settings = {
            main = {
              icons-enabled = "no";
              # line-height= 10;
              horizontal-pad = 30;
              vertical-pad = 10;
              letter-spacing = 2;
              font = "monospace:size=22";
              dpi-aware = "yes";
              terminal = "${pkgs.foot}/bin/foot";
              # layer = "overlay";
            };
            colors = {
              text = "00ff00ff";
              selection = "ffeeffff";
              background = "000000cc";
            };

            border = {
              # width=1
              radius = 0;
              # width = 6;
            };
          };
        };

      i3status-rust = {
        enable = true;
        bars = {
          top = {
            blocks = [
              {
                block = "disk_space";
                path = "/";
                info_type = "available";
                interval = 60;
                warning = 20.0;
                alert = 10.0;
              }
              {
                block = "memory";
                format = " $icon $mem_used_percents ";
                format_alt = " $icon $swap_used_percents ";
                # warning_mem = " $icon $mem_used_percents ";
                # warning_swap = " $icon $swap_used_percents ";
              }
              {
                block = "cpu";
                interval = 1;
              }
              {
                block = "load";
                interval = 1;
                format = " $icon $1m ";
              }
              { block = "sound"; }
              {
                block = "time";
                interval = 60;
                format = " $timestamp.datetime(f:'%a %d/%m %R') ";
              }
            ];
            settings = {
              theme = {
                theme = "solarized-dark";
                overrides = {
                  idle_bg = "#123456";
                  idle_fg = "#abcdef";
                };
              };
            };
            icons = "awesome5";
            theme = "gruvbox-dark";
          };

        };
      };

      foot = {
        enable = true;
        # srver = {
        #   enable = true;
        # };
        settings = {
          main = {
            term = "xterm-256color";
            font = "FiraCode Nerd Font Mono:style=Regular:size=14";
            dpi-aware = "yes";
          };
          mouse = {
            hide-when-typing = "yes";
          };
          colors = {
            background = "222222";

          };
        };
      };
    };

    # xdg.configFile."yambar/config.yml".source = ./config.yml;
    # xdg.configFile."rootbar/config".source = ./config;
    # xdg.configFile."rootbar/style.css".source = ./style.css;
    # xdg.configFile."yambar/config.yml".source = (pkgs.formats.yaml { }).generate "something" {
    #   settings = {
    #     draw_bold_text_with_bright_colors = true;
    #     dynamic_title = true;
    #     live_config_reload = true;
    #     window.dimensions = {
    #       columns = 0;
    #       lines = 0;
    #     };
    #     scrolling = {
    #       history = 10000;
    #       multiplier = 3;
    #     };
    #   };
    # };

    wayland.windowManager.sway = {
      enable = true;



      config = {
        fonts = {
          names = [ "DejaVu Sans Mono" "FontAwesome5Free" ];
          style = "Bold Semi-Condensed";
          size = 0.1;
        };
        window = {

          border = 4; #12; is the same of title boarder

          # commands = [{ command = "border pixel 20";
          # criteria = { class = "*"; };
          # }];
        };
        # window.titlebar = false;
        # default_border none
        # default_border = 6;
        # titlebar_border_thickness = 2;
        # default_floating_border none font pango:monospace 3
        # # hide_edge_borders smart
        # titlebar_padding 1
        # titlebar_border_thickness 0
        # gaps inner 0
        # gaps outer 0
        # "titlebar_padding" = "1";

        keybindings =
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
            menu = "fuzzel";
            # config.wayland.windowManager.sway.config.menu = menu;

          in
          lib.mkOptionDefault
            {
              # "${modifier}+Return" = "exec ${pkgs.foot}/bin/foot";
              "${modifier}+y" = "kill";
              "${modifier}+u" = "workspace next";
              "${modifier}+o" = "exec foot -- ncpamixer";
              "${modifier}+p" = "exec ${menu}";
              "${modifier}+d" = "exec ${menu}";
              "${modifier}+Shift+p" = ''
                			      exec grim -g "$(slurp -d)" - | wl-copy && wl-paste > ~/lastscreen.png'';
            };

        bars = [
          {
            mode = "dock";
            statusCommand = "i3status-rs ~/.config/i3status-rust/config-top.toml";
            hiddenState = "hide";
            position = "top";
            workspaceButtons = true;
            workspaceNumbers = true;
            fonts = {
              names = [ "monospace" ];
              size = 8.0;
            };
          }
        ];
        input = {
          "*" = {
            xkb_layout = "us";
            #xkb_options = "caps:swapescape";
            repeat_delay = "200";
            repeat_rate = "35";
          };
        };
        modifier = "Mod4";
        terminal = "foot";
        startup = [
          # { command = ""; }
        ];
      };
    };
    home.packages = with pkgs;[
      # tui
      
      neovim-qt
	    helix
      nil
      # emacs
      virtualbox
      nodejs
      kakoune
      eww-wayland
      pulseaudio
      # yambar
      # nvim-config.packages.x86_64-linux.default

      # cli
      # timer
      procs
      tree
      fd
      du-dust
      bat
      hexyl
      unzip
      ripgrep

      # gui
      # alacritty
      foot
      via
      qmk
      ncpamixer # audio control
      zathura # pdf viewer
      imv # image viewer
      mpv # video player

      # languages
      cargo
      clang
      zls
      zig

      #wayland
      sway
      # yambar
      fuzzel
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


  # -------------------- SWAY
  environment.systemPackages = with pkgs; [
    git
    google-chrome
    discord
    obs-studio

  ];

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };

  # enable sway window manager
  programs = {
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
