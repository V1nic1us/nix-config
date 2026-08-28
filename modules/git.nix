{
  programs.git = {
    enable = true;
    extraConfig = {
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
