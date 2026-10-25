{ ... }:
{
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;

  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
      Defaults passprompt="%u password: "
    '';
  };

  environment.sessionVariables = {
    SUDO_PROMPT = "%u password: ";
  };
}
