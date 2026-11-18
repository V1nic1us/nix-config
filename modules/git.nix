{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "V1nic1us";
        email = "marcusvinicius.mds16@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
  };
}
