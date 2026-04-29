# dotfiles

[English](README.md) | [日本語](README.ja.md)

My personal dotfiles for macOS.

This repository uses Nix, nix-darwin, Home Manager, and flakes.

Home Manager is integrated into nix-darwin, so daily updates are applied with `./rebuild.sh`.

## Quick Start

Clone this repository.

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Run the setup script.

```bash
./setup.sh
```

`setup.sh` is for a fresh macOS environment.

It checks Nix, creates `local.nix` if needed, and runs either `bootstrap.sh` or `rebuild.sh` depending on whether nix-darwin is already installed.

`local.nix` is ignored by Git.

Example:

```nix
{
  username = "your-macos-username";
  hostname = "Your-MacBook-Air";

  git = {
    name = "your-git-name";
    email = "you@example.com";
  };
}
```

If Nix is not installed, `setup.sh` asks before running the official Nix installer.

After installing Nix, restart the terminal and run setup again.

```bash
cd ~/dotfiles
./setup.sh
```

## Structure

```text
.
├── flake.nix                 # Entry point (local darwinConfiguration)
├── flake.lock
├── local.nix                 # Local machine config (ignored by Git)
├── setup.sh                  # Fresh macOS setup
├── bootstrap.sh              # Initial nix-darwin activation
├── rebuild.sh                # Daily rebuild
├── .gitignore
├── hosts/darwin/             # nix-darwin system config
├── home/                     # home-manager modules
│   ├── default.nix           # Home Manager entry point
│   ├── packages.nix          # All packages
│   ├── git.nix               # Git
│   ├── shell.nix             # Zsh
│   ├── prompt.nix            # Starship
│   └── terminals.nix         # Terminal config links
└── configs/                  # Dotfiles (linked via home-manager)
    └── ghostty/              # Ghostty
```

## Scripts

### `setup.sh`

Fresh macOS setup.

```bash
./setup.sh
```

### `bootstrap.sh`

Initial nix-darwin activation.

Use this when Nix and `local.nix` already exist, but `darwin-rebuild` is not installed yet.

```bash
./bootstrap.sh
```

Usually `setup.sh` runs this automatically.

### `rebuild.sh`

Daily rebuild after editing configs.

```bash
./rebuild.sh
```

## Daily Usage

Apply changes.

```bash
cd ~/dotfiles
./rebuild.sh
```

Update flake inputs.

```bash
cd ~/dotfiles
nix flake update
./rebuild.sh
```

Check scripts.

```bash
bash -n setup.sh
bash -n bootstrap.sh
bash -n rebuild.sh
```

Check whether `local.nix` is ignored by Git.

```bash
git check-ignore -v local.nix
```

Expected priority:

```text
/run/current-system/sw/bin
/etc/profiles/per-user/<username>/bin
/opt/homebrew/bin
```

## Requirements

```text
macOS
Apple Silicon Mac
Git
Internet connection for first setup
```

Nix is not required before running `setup.sh`.

If Nix is missing, `setup.sh` will ask before installing it.
