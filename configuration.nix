# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ pkgs, lib, home-manager, ... }:
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
  # timer = [ ./pkgs/timer.nix ];

in
{
  imports =
    [
      ./hardware-configuration.nix
      home-manager.nixosModules.default
    ];

  nix = {
    package = pkgs.nixFlakes;

    settings = {
      extra-experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs.config =
    {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "google-chrome"
      ];
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

  console.useXkbConfig = true; # use xkbOptions in tty.



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
    shell = pkgs.bash;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # home-manager.useUserPackages = true;
  home-manager.users.alberto = { config, pkgs, lib, ... }: {
    home.stateVersion = "23.05";
    # programs.neovim =
    #   {
    #     enable = true;
    #     package = pkgs.neovim-nightly.overrideAttrs (_: { CFLAGS = "-O3"; });
    #     vimAlias = true;
    #     viAlias = true;
    #     withNodeJs = true;
    #     withPython3 = true;
    #     withRuby = false;
    #     extraConfig = ''
    #       let mapleader=" "
    #
    #       lua <<EOF
    #       require("config.general")
    #       require("config.remaps")
    #       EOF
    #     '';
    #     plugins = with pkgs.nvimPlugins; [
    #       {
    #         plugin = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars;
    #         type = "lua";
    #         config = ''
    #
    #           require("config.treesitter")
    #       '';
    #       }
    #       nvim-treesitter-textobjects
    #       nvim-ts-rainbow
    #       {
    #         plugin = telescope;
    #         type = "lua";
    #         config = ''
    #           require("config.telescope")
    #         '';
    #       }
    #       telescope-file-browser
    #       plenary
    #       {
    #         plugin = nvim-tree;
    #         type = "lua";
    #         config = ''
    #           require("config.tree")
    #         '';
    #       }
    #       nvim-web-devicons
    #       {
    #         plugin = which-key;
    #         type = "lua";
    #         config = ''
    #           vim.api.nvim_set_option("timeoutlen", 300)
    #           require("which-key").setup({})
    #         '';
    #       }
    #       {
    #         plugin = Comment;
    #         type = "lua";
    #         config = ''
    #           require("config.comment")
    #         '';
    #       }
    #       vim-surround
    #       vim-repeat
    #       {
    #         plugin = gitsigns;
    #         type = "lua";
    #         config = ''
    #           require("gitsigns").setup()
    #         '';
    #       }
    #       {
    #         plugin = dashboard-nvim;
    #         type = "lua";
    #         config = ''
    #           require("config.dashboard")
    #         '';
    #       }
    #       {
    #         plugin = oceanic-next;
    #         type = "lua";
    #         config = ''
    #           require("config.theme")
    #         '';
    #       }
    #       {
    #         plugin = indent-blankline;
    #         type = "lua";
    #         config = ''
    #           require("config.blankline")
    #         '';
    #       }
    #       lualine
    #       nvim-navic
    #       {
    #         plugin = nvim-colorizer;
    #         type = "lua";
    #         config = ''
    #           require("colorizer").setup()
    #         '';
    #       }
    #       {
    #         plugin = dressing;
    #         type = "lua";
    #         config = ''
    #           require("dressing").setup()
    #         '';
    #       }
    #       popup
    #     ];
    #     extraPackages = with pkgs; [
    #       # Essentials
    #       nodePackages.npm
    #       nodePackages.neovim
    #
    #       # Telescope dependencies
    #       ripgrep
    #       fd
    #     ];
    #   };
    #


    ## sldfdlsfj l

    services = {
      gammastep = { provider = "geoclue2"; enable = true; };
      # polybar = {
      #
      #   enable = true;
      #   script = "polybar bar &";
      #   config = {
      #     "bar/top" = {
      #       monitor = "VGA-1";
      #       width = "100%";
      #       height = "3%";
      #       radius = 0;
      #       modules-center = "date";
      #     };
      #     "module/date" = {
      #       type = "internal/date";
      #       internal = 5;
      #       date = "%d.%m.%y";
      #       time = "%H:%M";
      #       label = "%time%  %date%";
      #     };
      #   };
      #   settings = {
      #     "module/volume" = {
      #       type = "internal/pulseaudio";
      #       format.volume = "<ramp-volume> <label-volume>";
      #       label.muted.text = "🔇";
      #       label.muted.foreground = "#666";
      #       ramp.volume = [ "🔈" "🔉" "🔊" ];
      #       click.right = "pavucontrol &";
      #     };
      #   };
      # };

    };
    #xdg.enable = true;

    programs = {

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
              font = "monospace:size=20";
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
        settings = {
          main = {
            term = "xterm-256color";
            font = "FiraCode Nerd Font Mono:style=Regular:size=10";
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


      config = rec {
        fonts = {
          names = [ "DejaVu Sans Mono" "FontAwesome5Free" ];
          style = "Bold Semi-Condensed";
          size = 0.1;
        };
        window = {
          border = 12;
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
              "${modifier}+Shift+q" = "kill";
              "${modifier}+u" = "workspace next";
              "${modifier}+o" = "exec pavucontrol";
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
            xkb_options = "caps:swapescape";
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
      neovim
      kakoune
      eww-wayland
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
      alacritty # gpu accelerated terminal
      foot
      pavucontrol
      zathura
      imv
      # google-chrome

      # languages 
      cargo
      clang
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
  ];




  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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

