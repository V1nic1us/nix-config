{ pkgs, ... }:
{
  # O arquivo do usuário tem prioridade sobre os padrões do Plasma em /etc/xdg.
  xdg.configFile."kdeglobals" = {
    source = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
    force = true;
  };
}
