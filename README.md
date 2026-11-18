# Configuração Nix portátil

Configuração inicial com Nix Flakes e Home Manager para reproduzir o mesmo
ambiente de usuário em computadores NixOS. O perfil usa Kitty como
terminal, instala Discord, Zed e btop e inclui um módulo NixOS para o KDE
Plasma 6 e Steam.
O idioma do sistema é inglês (`en_US.UTF-8`), com teclado brasileiro ABNT2.
O KDE Plasma usa o tema escuro Breeze por padrão.

## Instalação portátil (UEFI)

O instalador `install.sh` pede a partição destinada ao NixOS e o tamanho do
swap em GiB. Pressionar Enter usa 16 GiB; informar `0` desativa o swap. Ele
reutiliza a partição EFI FAT32 existente no mesmo disco,
sem formatá-la. A partição do NixOS **é apagada** e formatada em ext4. É
necessário deixar pelo menos 16 GiB além do tamanho escolhido para swap.
O instalador exige uma única partição EFI nesse disco e uma ISO iniciada em
modo UEFI. Se o disco ainda não tiver partições, crie a partição EFI e a
partição do sistema antes de executar o instalador.

Na ISO minimal oficial, conecte à internet e execute:

```sh
git clone https://github.com/V1nic1us/nix-config.git
cd nix-config
sudo bash install.sh
```

Digite `APAGAR` após conferir o resumo dos dispositivos. A instalação cria
`viniv` com a senha inicial descrita abaixo, habilita KDE Plasma 6, SDDM,
rede, áudio e Steam. O Home Manager instala Discord, Zed e btop e configura
Git, Kitty, Zsh e Fastfetch. O instalador copia a configuração para
`/etc/nixos`, onde ela pode ser atualizada com
`sudo nixos-rebuild switch --flake /etc/nixos#portable`.
Durante a instalação, o registro fica em `/mnt/nix-config-install.log`;
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
