{ pkgs, lib, config, ... }:
let

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
      })
      x)
      list);
in
{

  home = {

    packages = with pkgs;[
      # tui

      # neovim-qt
      # python3
      helix
      i2c-tools
      nil
      nixpkgs-fmt
      # emacs
      # virtualbox
      # nodejs
      # kakoune
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

      # distrobox
      # wev # window wayalnd event
      # blockbench-electron # modeling
      # calc

      # gui
      # alacritty
      foot
      # via
      nushell
      # qmk
      ncpamixer # audio control
      # zathura # pdf viewer
      imv # image viewer
      # mpv # video player

      # languages
      # cargo
      # clang
      # clang-tools
      # zls
      # python3Packages.python-lsp-server
      # zig

      #wayland
      sway
      # yambar
      fuzzel
      # dbus-sway-environment
      # configure-gtk
      wayland
      xdg-utils # for opening default programs when clicking links
      # dracula-theme # gtk theme
      # gnome3.adwaita-icon-theme # default gnome cursors
      swaylock
      nerdfonts
      swayidle
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      mako # notification system developed by swaywm maintainer
      wdisplays # tool to configure displays

    ];


    # sessionPath = [ "/home/${user}/.config/emacs/bin/" ];
    sessionVariables = {
      EDITOR = "hx";
    };
    stateVersion = "23.05";
    username = "alberto";
    homeDirectory = "/home/alberto";
  };


  xdg =
    {
      desktopEntries = { } // (deletexdg [
        # "emacs"
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

    nushell = import ./nushell pkgs;

    helix = import ./helix;



      # doom-emacs = {
      #   enable = true;
      #   doomPrivateDir = ./config/doom; # Directory containing the config.el, init.el
      # };
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
"${modifier}+q" = "kill";
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


}
