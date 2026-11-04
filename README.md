# dotfiles

[日本語](README.ja.md) · [日本語セットアップ](docs/setup.ja.md)

Dotfiles managed with Nix (nix-darwin / Home Manager / flakes).
Supports Apple Silicon macOS and x86_64 Linux / WSL.

## Quick Start

Nix must be available, and `user.name` and `user.email` must be set in your global Git configuration.
If preparation is needed, start with [Initial Setup](docs/setup.md#initial-setup).

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
make init
```

`make init` generates `~/.config/dotfiles/local.nix` and applies the configuration for the first time (preserving an existing file).
It does not install Nix itself. Administrator authentication is required on macOS.
See [Git Configuration Migration](docs/setup.md#git-configuration-migration) for how existing Git settings are handled.

If make is unavailable, you can run `./scripts/init-local.sh && ./scripts/bootstrap.sh` directly.
Reopen your terminal after applying the configuration. On Linux/WSL, [switch to zsh](docs/setup.md#zsh) if needed.

## Daily Usage

Run these commands inside the repository. Use `make` / `make help` to list available commands.

```bash
# Apply configuration changes
make rebuild
```

To update dependencies, choose one of the following (only `flake.lock` is updated).

| Command | Update scope |
| --- | --- |
| `make update-nixpkgs` | Nixpkgs only |
| `make update-all` | All inputs |

```bash
# Review the update diff, then apply if everything looks correct
git diff -- flake.lock
make rebuild
```

See the notes on [update scopes and pinned versions](docs/setup.md#updating-inputs) and [running scripts directly](docs/setup.md#running-scripts-directly) without make.
If you use a different location for `local.nix`, specify the same `DOTFILES_LOCAL_NIX` for initial and subsequent applications ([examples](docs/setup.md#localnix)).

## Structure

```text
.
├── Makefile                  # Command entry points (run make to list them)
├── flake.nix                 # Flake entry point
├── flake.lock                # Pinned flake inputs
├── local.nix.example         # Example machine-specific configuration
├── scripts/                  # Initialization and application scripts
│   ├── init-local.sh         # Generate local.nix
│   ├── bootstrap.sh          # Apply configuration for the first time
│   └── rebuild.sh            # Reapply configuration for daily use
├── home/                     # Home Manager modules
│   ├── common/               # Settings shared across all environments
│   │   ├── packages.nix      # Shared development tools and runtimes
│   │   ├── git.nix           # Git identity, LFS, and existing settings migration
│   │   ├── shell.nix         # Zsh, completion, and editor selection
│   │   ├── prompt.nix        # Starship
│   │   └── direnv.nix        # direnv and nix-direnv
│   ├── darwin/               # macOS-specific settings
│   │   ├── packages.nix      # macOS-specific packages
│   │   └── terminals.nix     # Ghostty configuration link
│   └── linux/                # Linux / WSL settings
│       ├── packages.nix      # Linux-specific packages
│       ├── session.nix       # Session environment variables
│       └── wsl.nix           # WSL-specific settings and browser integration
├── hosts/darwin/             # nix-darwin system settings
│   └── default.nix           # Nix, users, and sudo authentication
├── pkgs/                     # Custom package definitions
│   └── nodejs-bin.nix        # Node.js (official binaries)
├── configs/ghostty/
│   └── config.ghostty        # Ghostty appearance and keybindings
└── docs/setup.md             # Setup and usage notes
```

## Requirements

- macOS: Apple Silicon
- Linux / WSL: x86_64 ([WSL2 / systemd preparation](docs/setup.md#wsl))
- Git and Nix (make is optional)
