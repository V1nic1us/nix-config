{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        type = "small";
        padding.right = 2;
      };

      display = {
        separator = "  ->  ";
        color = {
          keys = "blue";
          title = "cyan";
        };
      };

      modules = [
        "title"
        "separator"
        {
          type = "os";
          key = "Sistema";
        }
        {
          type = "host";
          key = "Dispositivo";
        }
        {
          type = "kernel";
          key = "Kernel";
        }
        {
          type = "uptime";
          key = "Ligado há";
        }
        {
          type = "packages";
          key = "Pacotes";
        }
        {
          type = "shell";
          key = "Shell";
        }
        {
          type = "display";
          key = "Tela";
        }
        {
          type = "de";
          key = "Ambiente";
        }
        {
          type = "wm";
          key = "Compositor";
        }
        {
          type = "terminal";
          key = "Terminal";
        }
        {
          type = "cpu";
          key = "Processador";
        }
        {
          type = "gpu";
          key = "Vídeo";
        }
        {
          type = "memory";
          key = "Memória";
        }
        {
          type = "disk";
          key = "Disco";
        }
        {
          type = "localip";
          key = "IP local";
        }
        {
          type = "battery";
          key = "Bateria";
        }
        "break"
        "colors"
      ];
    };
  };
}
