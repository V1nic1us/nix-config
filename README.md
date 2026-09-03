# Configuração Nix portátil

Configuração inicial com Nix Flakes e Home Manager para reproduzir o mesmo
ambiente de usuário em vários dispositivos Linux. O perfil usa Kitty como
terminal, instala Discord e inclui um módulo NixOS para o KDE Plasma 6 e Steam.

## Primeiro uso

1. Instale o Nix com suporte a `nix-command` e `flakes`.
2. Clone este diretório como `~/nix-config`.
3. Dentro dele, execute:

   ```sh
   nix run github:nix-community/home-manager -- switch --flake .#viniv
   ```

Nas próximas atualizações, use:

```sh
home-manager switch --flake ~/nix-config#viniv
```

## Manutenção

```sh
# Atualizar as dependências e registrar as versões em flake.lock
nix flake update

# Verificar a configuração sem aplicá-la
nix flake check

# Formatar os arquivos
nix fmt
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

## Teste gráfico no QEMU

O flake inclui a configuração temporária `desktop-vm`, que importa o módulo de
desktop e o perfil Home Manager. Para construir e iniciar a VM sem alterar o
sistema host, execute na raiz do repositório:

```sh
nixos-rebuild build-vm --flake .#desktop-vm
./result/bin/run-nix-config-vm-vm
```

A tela de login do SDDM deve aparecer. Entre com o usuário `viniv` e a senha
`nixos`; essas credenciais existem somente na imagem de teste. A VM recebe 4 GB
de RAM, quatro núcleos e um disco descartável de 20 GB. Feche a janela do QEMU
para encerrar o teste.

### Instalação automatizada na ISO minimal

Depois de clonar este repositório na ISO, execute:

```sh
cd nix-config
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake .#qemu-install \
  --disk main /dev/vda
```

O `disko-install` usa o layout declarativo em
`modules/nixos/disk-config.nix`: apaga o disco informado, cria uma tabela GPT,
uma partição de boot para o GRUB, uma partição ext4 para o sistema e uma swap de
8 GiB. Substitua `/dev/vda` no comando se o disco de destino tiver outro nome.
Confira o dispositivo com `lsblk` antes de executar, pois seu conteúdo será
apagado.

Não coloque senhas, tokens ou chaves privadas neste repositório. Para segredos,
adicione posteriormente uma solução como `sops-nix` ou `agenix`.
