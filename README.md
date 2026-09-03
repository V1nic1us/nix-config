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

Este procedimento instala o perfil `qemu-install` a partir da ISO minimal do
NixOS. A configuração atual usa GRUB em modo BIOS e foi preparada para uma VM
QEMU com pelo menos 4 GiB de memória e um disco de 20 GiB ou maior.

> **Atenção:** o Disko apaga completamente o disco indicado no comando. Não use
> este procedimento em um disco que contenha arquivos que precisam ser
> preservados.

1. Baixe a ISO minimal na [página oficial do NixOS](https://nixos.org/download/),
   conecte-a à VM e inicialize pelo modo BIOS legado.

2. No terminal da ISO, configure o teclado brasileiro:

   ```sh
   loadkeys br-abnt2
   ```

3. Verifique a conexão com a internet. Em uma VM com rede cabeada virtual, o
   DHCP normalmente é configurado automaticamente:

   ```sh
   ping -c 3 cache.nixos.org
   ```

4. Liste os dispositivos e identifique cuidadosamente o disco de destino:

   ```sh
   lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS,MODEL
   ```

   No QEMU, ele normalmente aparece como `/dev/vda`. A mídia da ISO geralmente
   aparece como `/dev/sr0` e não deve ser usada como destino. O disco precisa
   ter mais de 8 GiB, pois a configuração reserva 8 GiB exclusivamente para
   swap.

5. Obtenha o Git temporariamente pelo Nix e clone este repositório:

   ```sh
   nix shell nixpkgs#git -c git clone \
     https://github.com/V1nic1us/nix-config.git
   cd nix-config
   ```

6. Confirme que o Flake pode ser avaliado antes de modificar o disco:

   ```sh
   nix flake check
   ```

7. Execute a instalação, substituindo `/dev/vda` se o passo 4 mostrou outro
   disco:

   ```sh
   sudo nix run github:nix-community/disko/latest#disko-install -- \
     --flake .#qemu-install \
     --disk main /dev/vda
   ```

   O `disko-install` avalia o perfil, apaga e prepara o disco, monta os sistemas
   de arquivos e instala o NixOS. Não é necessário executar `nixos-install`
   separadamente.

8. Quando a instalação terminar com a mensagem `disko-install succeeded`,
   reinicie e remova a ISO da VM:

   ```sh
   reboot
   ```

Após iniciar pelo disco instalado, entre no SDDM com o usuário `viniv` e a
senha `nixos`. Essas credenciais são destinadas somente ao ambiente de teste.

O `disko-install` usa o layout declarativo em
`modules/nixos/disk-config.nix`: apaga o disco informado, cria uma tabela GPT,
uma partição de boot para o GRUB, uma partição ext4 para o sistema e uma swap de
8 GiB.

Não coloque senhas, tokens ou chaves privadas neste repositório. Para segredos,
adicione posteriormente uma solução como `sops-nix` ou `agenix`.
