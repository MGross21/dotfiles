{ config, lib, ... }:
let
  rootLogin = config.host.autoUpgrade;
  tailnetRanges = [
    "100.64.0.0/10"
    "fd7a:115c:a1e0::/48"
  ];
in
{
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = if rootLogin then "prohibit-password" else "no";
      AllowUsers = [
        config.user.name
      ]
      ++ lib.optionals rootLogin (map (range: "root@${range}") tailnetRanges);
    };
  };

  users.users.root.openssh.authorizedKeys.keys = lib.mkIf rootLogin config.user.sshKeys;

}
