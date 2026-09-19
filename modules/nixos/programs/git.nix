{ ... }:
{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";

      user = {
        name = "Michael Gross";
        email = "mgrossofficial@gmail.com";
      };

      core = {
        editor = "nvim";
        autocrlf = "input";
      };

      fetch.prune = true;
      pull.ff = "only";
      push.autoSetupRemote = true;
      rebase.autoStash = true;

      credential."https://github.com".helper = [
        ""
        "!/run/current-system/sw/bin/gh auth git-credential"
      ];

      credential."https://gist.github.com".helper = [
        ""
        "!/run/current-system/sw/bin/gh auth git-credential"
      ];
    };
  };
}
