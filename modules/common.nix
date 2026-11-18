{ pkgs, lib, ... }:
let
  discordSource = pkgs.discord.passthru.source;
  emptyDiscordModules = [
    "discord_rpc"
    "discord_zstd"
  ];
  moduleSrc = name: pkgs.fetchurl { inherit (discordSource.modules.${name}) url hash; };
  extractLine =
    name:
    "brotli -d < ${moduleSrc name} | tar xf - --strip-components=1 -C $out/opt/Discord/modules/${name}";
  discord = pkgs.discord.override {
    unwrappedDiscord = pkgs.discord.passthru.unwrappedDiscord.overrideAttrs (old: {
      installPhase = lib.replaceStrings (map extractLine emptyDiscordModules) (map (
        name: "if [ -s ${moduleSrc name} ]; then ${extractLine name}; fi"
      ) emptyDiscordModules) old.installPhase;
    });
  };
in
{
  home.packages = [
    discord
    pkgs.zed-editor
  ];
}
