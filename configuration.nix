# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  configure-gtk-static = pkgs.writeTextFile {
    name = "configure-gtk-static";
    destination = "/bin/configure-gtk-static";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema="org.gnome.desktop.interface"
      gsettings set $gnome-schema gtk-theme 'adw-gtk3-dark'
      gsettings set $gnome-schema icon-theme 'Papirus-Dark'
      gsettings set $gnome-schema cursor-theme 'Adwaita'
      gsettings set $gnome-schema font-name 'Rubik 11'
      gsettings set $gnome_schema color-scheme 'prefer-dark'
    '';
  };

  swayConfig = pkgs.writeText "greetd-sway-config" ''
    exec_always configure-gtk-static
    # `-l` activates layer-shell mode. Notice that `swaymsg exit` will run after gtkgreet.
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -c sway; swaymsg exit"
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
  '';

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
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
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
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      config="/home/arnau/.config/gtk-3.0/settings.ini"
      if [ ! -f "$config" ]; then exit 1; fi

      gnome_schema="org.gnome.desktop.interface"
      gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      cursor_theme="$(grep 'gtk-cursor-theme-name' "$config" | sed 's/.*\s*=\s*//')"
      font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
      gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
      gsettings set "$gnome_schema" icon-theme "$icon_theme"
      gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
      gsettings set "$gnome_schema" font-name "$font_name"
      gsettings set $gnome_schema color-scheme 'prefer-dark'
    '';
  };

in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "b450-nix"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "es";
    xkbVariant = "cat";
  };

  # Configure console keymap
  console.keyMap = "es";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arnau = {
    isNormalUser = true;
    description = "Arnau";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    vulkan-tools
    pciutils
    neofetch
    sway
    swaylock
    waybar
    alacritty
    wayland
    xorg.xwininfo
    gnome3.adwaita-icon-theme
    glxinfo
    firefox
    git
    xdg-user-dirs
    fuzzel
    papirus-icon-theme
    starship
    pkg-config
    go
    xcur2png
    networkmanagerapplet
    xfce.thunar
    xfce.thunar-volman
    gvfs
    xfce.thunar-archive-plugin
    vscode
    gnome.file-roller
    scrcpy
    pavucontrol
    gnome.gnome-disk-utility
    ventoy-bin
    udisks
    adw-gtk3
    dotter
    glib
    xdg-utils
    gsettings-desktop-schemas
    lxappearance
    polkit_gnome
    dbus-sway-environment
    configure-gtk
    nixfmt
    usbutils
    libva-utils
    swaysettings
    swaynotificationcenter
    autotiling-rs
    grim
    slurp
    wl-clipboard
    android-tools
  ];

  fonts.fonts = with pkgs; [ fira-code fira-code-symbols rubik font-awesome ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Programs:
  programs.sway.enable = true;
  programs.sway.wrapperFeatures.gtk = true;
  programs.dconf.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Printing
  services.printing.enable = true;
  services.avahi.enable = true;
  # for a WiFi printer
  services.avahi.openFirewall = true;

  #OpenGL    
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  #PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  #Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  #Udisks
  services.udisks2.enable = true;

  #gvfs
  services.gvfs.enable = true;
  services.dbus.enable = true;

  #flatpak
  services.flatpak.enable = true;

  #xdg-portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall =
      true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall =
      true; # Open ports in the firewall for Source Dedicated Server
  };

  #services.greetd = {
  #  enable = true;
  #  settings = {
  #    default_session = {
  #      command = "${pkgs.sway}/bin/sway --config ${swayConfig}";
  #    };
  #  };
  #};
  #
  #environment.etc."greetd/environments".text = ''
  #  sway
  #  bash
  #'';

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

