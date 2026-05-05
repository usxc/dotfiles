# dotfiles

[English](README.md) | [日本語](README.ja.md)

My personal dotfiles for macOS.

This repository uses Nix, nix-darwin, Home Manager, and flakes.

Home Manager is integrated into nix-darwin, so daily updates are applied with `./rebuild.sh`.

## Initial Setup

### macOS

#### 1. Install Nix

Install Nix first if it is not already installed.

Using the Nix modern installer with flakes enabled:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```
The installer may ask for confirmation before making changes to the system.
When prompted with Proceed? `([Y]es/[n]o/[e]xplain)`, press Enter or type `y`.

After installation, restart your terminal.

Check that Nix is available:

```bash
nix --version
```

#### 2. Clone this repository

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### 3. Create `local.nix`

Create `local.nix` from the example file.

```bash
cp local.nix.example local.nix
$EDITOR local.nix
```

`local.nix` contains machine-local settings.

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

You can check each value with the following commands.

| key | command |
|---|---|
| `username` | `id -un` |
| `hostname` | `scutil --get LocalHostName` or `hostname -s` |
| `git.name` | `git config --global user.name` |
| `git.email` | `git config --global user.email` |

If Git user name or email is not configured yet, configure them first.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Then write the same values to `local.nix`.

`local.nix` is specific to this Mac and should not be committed to Git.

#### 4. Bootstrap nix-darwin

Run the initial nix-darwin activation.

```bash
./bootstrap.sh
```

This applies the initial nix-darwin and Home Manager configuration.

After this step, use `./rebuild.sh` for daily updates.

## Daily Usage

Apply configuration changes.

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

## Scripts

### `bootstrap.sh`

Initial nix-darwin activation.

Use this only for the first setup, when Nix is installed but `darwin-rebuild` is not available yet.

```bash
./bootstrap.sh
```

### `rebuild.sh`

Daily rebuild after editing configs.

```bash
./rebuild.sh
```

## Structure

```text
.
├── flake.nix                 # Entry point
├── flake.lock
├── local.nix.example         # Example local machine config
├── local.nix                 # Local machine config (ignored by Git)
├── bootstrap.sh              # Initial nix-darwin activation
├── rebuild.sh                # Daily rebuild
├── .gitignore
├── hosts/darwin/             # nix-darwin system config
├── home/                     # Home Manager modules
│   ├── default.nix           # Home Manager entry point
│   ├── packages.nix          # Packages
│   ├── git.nix               # Git
│   ├── shell.nix             # Zsh
│   ├── prompt.nix            # Starship
│   └── terminals.nix         # Terminal config links
└── configs/                  # Dotfiles linked by Home Manager
    └── ghostty/              # Ghostty
    └── aerospace/            # AeroSpace
```

## Requirements

```text
macOS
Apple Silicon Mac
Nix
Git
```
