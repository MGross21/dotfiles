{ ... }:
{
  services.gnome.gnome-keyring.enable = true;

  security.sudo.extraConfig = ''
    Defaults pwfeedback
    Defaults passprompt="%u password: "
  '';

  environment.sessionVariables.SUDO_PROMPT = "%u password: ";
}
