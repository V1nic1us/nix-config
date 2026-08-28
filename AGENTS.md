# Repository Guidelines

## Project Structure & Module Organization

This is a Nix Flake that manages a portable user environment with Home Manager.
`flake.nix` declares inputs, the target system and username, and exports both
the Home Manager profile and the NixOS desktop module. `home.nix` is the entry
point for user-level configuration and imports the focused modules in
`modules/`:

- `common.nix` contains shared packages and general programs.
- `git.nix`, `shell.nix`, `kitty.nix`, and `fastfetch.nix` own one concern each.
- `modules/nixos/desktop.nix` is system-level NixOS configuration (Plasma,
  SDDM, Steam, kernel), imported by a host configuration rather than Home
  Manager.
- `assets/` holds tracked static files referenced from Nix, such as the user
  avatar.

## Build, Test, and Development Commands

Run commands from the repository root:

```sh
nix fmt                              # Format Nix sources with nixfmt
nix flake check                      # Evaluate and validate flake outputs
home-manager switch --flake .#viniv  # Apply the user profile
nix flake update                     # Update inputs and flake.lock
```

For a NixOS machine importing `nixosModules.desktop`, apply the host config
with `sudo nixos-rebuild switch --flake .#<hostname>`. Run `nix fmt` and
`nix flake check` before committing. There is no automated test suite; a
successful flake check is the required baseline validation.

## Coding Style & Naming Conventions

Use the formatter instead of hand-formatting. Follow the existing Nix style:
two-space indentation, one attribute per line when it improves readability,
and focused attribute sets. Keep modules small and name them after their
responsibility, e.g. `modules/kitty.nix`. Add user-level modules to the
`imports` list in `home.nix`; expose reusable system modules from `flake.nix`.
Use lowercase, hyphenated filenames for assets, for example
`assets/sunny-shadow-slave.png`.

## Commit & Pull Request Guidelines

Recent commits use concise imperative subjects, such as `Configure desktop
profile and Git defaults`. Keep subjects short, capitalized, and specific to
the change. In pull requests, explain the user-visible configuration change,
list validation commands run, and call out updates to `flake.lock` or assets.
Include screenshots only for visible desktop or terminal presentation changes.

## Security & Configuration

Do not commit passwords, tokens, SSH keys, or machine-specific secrets. Use a
secret-management solution such as `sops-nix` or `agenix` if secrets are needed.
Changing `home.stateVersion` requires deliberate migration review. Adjust
`username` and `system` in `flake.nix` when targeting another user or
architecture.
