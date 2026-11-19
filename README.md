# Configuração Nix portátil

Configuração inicial com Nix Flakes e Home Manager para reproduzir o mesmo
ambiente de usuário em computadores NixOS. O perfil usa Kitty como
terminal, instala Discord, Zed e btop e inclui um módulo NixOS para o KDE
Plasma 6 e Steam.
O idioma do sistema é inglês (`en_US.UTF-8`), com teclado brasileiro ABNT2.
O KDE Plasma usa o tema escuro Breeze por padrão.

## Instalação portátil (UEFI)

O `install.sh` encontra os SSDs e HDs internos. Se houver apenas um, ele o
seleciona automaticamente; se houver vários, mostra uma lista e pede o número
do disco. Depois pergunta o tamanho do swap em GiB: Enter usa 16 GiB e `0`
desativa o swap.

**O disco escolhido será apagado por inteiro.** Após mostrar o nome e o tamanho
dele, o instalador exige que você digite `APAGAR`. Só então ele cria a tabela
GPT, uma partição EFI FAT32 de 1 GiB e uma partição ext4 com o espaço restante.
Use este fluxo apenas quando puder apagar todas as partições do disco escolhido;
ele não preserva outro sistema instalado. É preciso iniciar a ISO em modo UEFI
e ter espaço para o swap escolhido, mais 17 GiB para EFI e sistema.

Na ISO minimal oficial, conecte à internet e execute uma linha por vez:

```sh
git clone https://github.com/V1nic1us/nix-config.git
cd nix-config
sudo bash install.sh
```

Se o repositório já estiver clonado na ISO, atualize-o e execute o instalador:

```sh
cd ~/nix-config
git pull
sudo bash install.sh
```

Confira o disco listado antes de digitar `APAGAR`. A instalação cria `viniv`
com a senha inicial descrita abaixo, habilita KDE Plasma 6, SDDM, rede, áudio
e Steam. O Home Manager instala Discord, Zed e btop e configura
Git, Kitty, Zsh e Fastfetch. O instalador copia a configuração para
`/etc/nixos`, onde ela pode ser atualizada com
`sudo nixos-rebuild switch --flake /etc/nixos#portable`.
O terminal mostra as cinco etapas e o tempo decorrido. Durante a etapa longa
do NixOS, uma barra animada indica atividade e conta os itens copiados ou
compilados; ela não representa uma porcentagem nem estima o tempo restante.
O registro detalhado fica em `/mnt/nix-config-install.log`;
depois do reinício, em `/nix-config-install.log`.
Quando o instalador terminar, remova a ISO e reinicie o computador.

A senha inicial foi pedida pelo usuário para instalações repetidas. Troque-a
após o primeiro login em cada computador com `passwd`, pois uma senha fixa é
fraca para uso permanente. O instalador aplica a senha diretamente no sistema
instalado; ela não é gravada na configuração Nix nem no Nix store.

## Primeiro uso após a instalação

O `install.sh` já instala o NixOS e aplica o Home Manager junto com o sistema.
Depois de reiniciar e entrar como `viniv`, troque a senha inicial:

```sh
passwd
```

Para reaplicar a configuração instalada em `/etc/nixos` depois de editá-la,
execute:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#portable
```

## Manutenção

```sh
# Atualizar as dependências e registrar as versões em flake.lock
nix flake update

# Verificar a configuração sem aplicá-la
nix flake check

# Formatar os arquivos Nix
nix fmt -- flake.nix home.nix modules/*.nix modules/nixos/*.nix
```

Os pacotes compartilhados ficam em `modules/common.nix`. Preferências de Git e
shell estão em módulos próprios. Antes de usar outro nome de usuário ou uma
máquina ARM, ajuste `username` e `system` em `flake.nix`.

## Ambiente gráfico no NixOS

O ambiente gráfico é uma configuração do sistema, não do Home Manager. Importe
o módulo deste flake na configuração de cada máquina NixOS:

```nix
{
  inputs.nix-config.url = "path:/home/viniv/nix-config";

  outputs = { nixpkgs, nix-config, ... }: {
    nixosConfigurations.meu-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        nix-config.nixosModules.desktop
      ];
    };
  };
}
```

Depois, aplique com `sudo nixos-rebuild switch --flake .#meu-host`. O nixpkgs
atual fornece o módulo Plasma 6; ainda não existe uma opção `plasma7` para ser
ativada.
