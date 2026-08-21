{
  home.sessionVariables.TERMINAL = "kitty";

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      scrollback_lines = 10000;
      shell_integration = "enabled";
    };
  };
}
