{ config, ... }:
{
  programs.gh.enable = true;

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
    };
  };
}
