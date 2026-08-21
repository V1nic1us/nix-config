{
  programs.git = {
    enable = true;
    # Defina seus dados pessoais em modules/local.nix e importe-o em home.nix.
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
