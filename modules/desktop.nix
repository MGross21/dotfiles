{
  pkgs,
  lib,
  ...
}:
let
  isX86_64 = pkgs.stdenv.hostPlatform.isx86_64;

  papirus-red = pkgs.runCommand "papirus-icon-theme-red" {
    nativeBuildInputs = [ pkgs.papirus-folders ];
  } ''
    tmpdir=$(mktemp -d)
    cp -r ${pkgs.papirus-icon-theme}/share/icons/. $tmpdir/
    chmod -R u+w $tmpdir
    DISABLE_UPDATE_ICON_CACHE=1 papirus-folders -t $tmpdir/Papirus -C red
    DISABLE_UPDATE_ICON_CACHE=1 papirus-folders -t $tmpdir/Papirus-Dark -C red
    DISABLE_UPDATE_ICON_CACHE=1 papirus-folders -t $tmpdir/Papirus-Light -C red
    mkdir -p $out/share/icons
    cp -r $tmpdir/. $out/share/icons/
  '';
in
{
  imports = [
    ./desktops/hyprland.nix
  ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.printing.enable = true;

  security.pam.services.ly.enableGnomeKeyring = true;

  networking.firewall.allowedTCPPorts = [ 24800 ];

  environment.sessionVariables = {
    MOZ_DBUS_REMOTE = "1";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_GTK_TITLEBAR_DECORATION = "client";
    MOZ_DISABLE_SPLASH = "1";
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-vcs-plugin
      thunar-shares-plugin
    ];
  };

  programs.firefox.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      ghostty
      tumbler

      papirus-red
      papirus-folders

      spicetify-cli
      feh
      obs-studio
      kicad
      gimp
      rawtherapee
      gthumb
      libreoffice
      vscode
      spotify
      deskflow

      libxres
      gamemode
      xwayland
      qt5.qtbase
      qt5.qtwayland
      qt6.qtbase
      qt6.qtwayland

      pavucontrol

      libsecret
      seahorse
      hyprpolkitagent
      mcontrolcenter

      dunst

      nix-search-tv
    ]
    ++ lib.optionals isX86_64 (
      with pkgs;
      [
        discord
        steam
        zoom-us
      ]
    );

  fonts.packages = with pkgs; [
    jetbrains-mono
    ubuntu-classic
    nerd-fonts.ubuntu
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-monochrome-emoji
  ];
}
