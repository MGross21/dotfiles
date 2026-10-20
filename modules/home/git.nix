{
  config,
  lib,
  pkgs,
  ...
}:
let
  ghHelper = [
    ""
    "!${lib.getExe pkgs.gh} auth git-credential"
  ];
in
{
  home.packages = [ pkgs.gh ];

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";

      user = {
        name = config.user.fullName;
        inherit (config.user) email;
      };

      core = {
        editor = "nvim";
        autocrlf = "input";
      };

      fetch.prune = true;
      pull.ff = "only";
      push.autoSetupRemote = true;
      rebase.autoStash = true;

      credential."https://github.com".helper = ghHelper;
      credential."https://gist.github.com".helper = ghHelper;
    };
  };
}
