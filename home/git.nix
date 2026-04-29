{
  gitUser,
  ...
}: {
  programs.git = {
    enable = true;

    lfs.enable = true;

    settings = {
      user = {
        name = gitUser.name;
        email = gitUser.email;
      };

      init = {
        defaultBranch = "main";
      };

      core = {
        editor = "code --wait";
      };
    };
  };
}
