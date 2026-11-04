# Setup and Usage Notes

[日本語セットアップ](setup.ja.md)

For everyday use, see [Quick Start](../README.md#quick-start) / [Daily Usage](../README.md#daily-usage) in the README.

## Initial Setup

These steps are shared across Apple Silicon macOS and x86_64 Linux / WSL. Have Git and curl installed beforehand.
make is optional; you can run the scripts directly without it.

### 1. Prepare Nix

For WSL, check [WSL preparation](#wsl) first.
If Nix is not installed, install it with flakes enabled.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

After installation, reopen your terminal and verify that Nix is available.
If it is already available, there is no need to reinstall it.

```bash
nix --version
```

### 2. Clone the Repository

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Check Your Git Identity

Your name and email address are read from the global Git configuration to create the machine-specific configuration.
Global settings in `include` files and `~/.config/git/config` are also read, and `init-local.sh` checks that the required information is available.
If these values are not set, configure your own information.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

If you have already configured authentication, signing, or includes, also review [Git Configuration Migration](#git-configuration-migration).

### 4. Generate and Apply the Configuration

```bash
make init
```

This runs `./scripts/bootstrap.sh` after `./scripts/init-local.sh` succeeds. If initialization fails, the initial application does not proceed.
Without make, the equivalent commands are:

```bash
./scripts/init-local.sh && ./scripts/bootstrap.sh
```

The machine-specific configuration is generated outside the repository at `~/.config/dotfiles/local.nix` and is not tracked by Git.
See [local.nix](#localnix) for changing its location and handling existing files.
On macOS, nix-darwin and Home Manager settings are applied; on Linux/WSL, Home Manager settings are applied.
On macOS, the scripts request administrator authentication. `sudo make` is not required.
These scripts do not install Nix itself.

Reopen your terminal after applying the configuration.
To use zsh as your login shell on Linux/WSL, continue to [switching to zsh](#zsh).

## WSL

The Nix installation method described here uses WSL2 with systemd enabled.
If Nix is already available, skip reinstallation and proceed to [verifying Nix](#1-prepare-nix).

In PowerShell, check that the distribution you use has `VERSION` set to `2`.

```powershell
wsl --list --verbose
```

systemd requires WSL 0.67.6 or later.
Check with `wsl --version`. If your version is older or the command is unavailable, update with `wsl --update`.

Inside WSL, check whether systemd is running.

```bash
ps -p 1 -o comm=
```

If the output is `systemd`, this setup is complete.
Otherwise, enable the following setting in `/etc/wsl.conf` inside WSL.
Keep existing settings and set `systemd` to `true` in the `[boot]` section.
Add the section or option if it is missing.

```ini
[boot]
systemd=true
```

Run the following in PowerShell, then reopen WSL. This command stops all running WSL environments.

```powershell
wsl --shutdown
```

Check again with `ps -p 1 -o comm=`, then return to the [Nix installation steps](#1-prepare-nix).
For environment-specific details, such as installing systemd, see [Microsoft's official instructions](https://learn.microsoft.com/en-us/windows/wsl/systemd).
WSL support for Nix is described in the [official Nix Installer instructions](https://github.com/NixOS/nix-installer#in-wsl2).

## zsh

On Linux/WSL, applying the zsh configuration does not automatically change your login shell.
After the initial application, reopen your terminal and run the following if you want zsh as your login shell.

```bash
ZSH_PATH="$(command -v zsh)"

if [ -z "$ZSH_PATH" ]; then
  echo "zsh not found"
  exit 1
fi

if ! grep -qxF "$ZSH_PATH" /etc/shells; then
  printf '%s\n' "$ZSH_PATH" | sudo tee -a /etc/shells
fi

chsh -s "$ZSH_PATH"
```

On Linux, log in again. For WSL, run `wsl --shutdown` in PowerShell, then reopen WSL.

```bash
echo "$SHELL"
```

If the displayed path points to zsh, you are done.

## local.nix

`./scripts/init-local.sh` generates machine-specific settings at `~/.config/dotfiles/local.nix` by default.
See [local.nix.example](../local.nix.example) for the generated fields and values for each OS.

Existing files are not overwritten during normal execution.
For new files, a temporary file on the same filesystem is published using a hard link, preventing overwrites from concurrent runs as well.
Normal creation of new files stops if the destination does not support hard links. `--force` replaces the file as before.
If the destination is a directory or a broken symlink, the script stops with an error without changing the existing path.
If an existing file is present, `init-local.sh` exits successfully, so `make init` continues with the initial application using that configuration.
Specify `--force` explicitly only when you have reviewed the contents and want to regenerate the file. `make init` does not pass this option.

```bash
./scripts/init-local.sh --force
```

To change the location, specify a path outside the repository.
Relative paths are resolved from the directory where you run the command.
`make init` passes the same `DOTFILES_LOCAL_NIX` to both scripts.

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix make init
DOTFILES_LOCAL_NIX=/path/to/local.nix make rebuild
```

When running scripts directly, also pass the same path for generation, initial application, and subsequent applications.

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/init-local.sh &&
DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/bootstrap.sh
```

Specify the same path for subsequent applications as well.

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/rebuild.sh
```

To regenerate the file at a different location, also specify `DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/init-local.sh --force`.

## Git Configuration Migration

`init-local.sh` imports the global `user.name` and `user.email` Git settings.
[home/common/git.nix](../home/common/git.nix) sets this information, Git LFS, and the initial branch name in `~/.config/git/config`.
During initial and subsequent applications, the [migration script](../home/common/migrate-git-config.sh) cleans up only
`user.name`, `user.email`, and `init.defaultBranch` written directly in the existing `~/.gitconfig`.

The original contents are saved to `~/.gitconfig.before-dotfiles.XXXXXX`, and authentication, signing, aliases, and `include` / `includeIf` settings are preserved.
Included files and repository-specific settings are not modified. If no settings need changing, no files are rewritten and no new backups are created.
To change the default Git identity after applying the configuration, edit `git.name` / `git.email` in `local.nix` and reapply.

Home Manager's `.backup` setting is used to back up existing files
(`backupFileExtension = "backup"` on macOS and `switch -b backup` on Linux/WSL).
If an existing XDG configuration is backed up, the backup alone does not guarantee that authentication, signing, includes, and other settings remain active.
Compare the required settings with the backup and keep them in a form that remains effective after application.

## Running Scripts Directly

The Makefile provides entry points to the existing operations. Each script continues to handle OS detection and configuration generation and application.
The scripts are grouped in `scripts/`. Run the command examples below from the repository root.

### init-local.sh

Generates the machine-specific `local.nix`.
Detects platform, system, username, hostname, home directory, WSL status, and the global Git identity.

```bash
./scripts/init-local.sh
```

The supported combinations are `darwin` / `aarch64-darwin` and `linux` / `x86_64-linux`.
See [local.nix](#localnix) for the destination and `--force` behavior.

### bootstrap.sh

For the initial application. Requires Nix and a generated `local.nix`.

```bash
./scripts/bootstrap.sh
```

Invokes the nix-darwin flake input on macOS or the Home Manager flake input on Linux/WSL using `nix run`.
`--inputs-from .` uses this repository's inputs, and the command also runs with `--impure`.
Nix invocations explicitly include `--extra-experimental-features nix-command` and `--extra-experimental-features flakes`.

### rebuild.sh

For routine reapplication after configuration changes. This is the same operation as `make rebuild`.

```bash
./scripts/rebuild.sh
```

Runs the following depending on `platform` in `local.nix`:

```text
macOS:     darwin-rebuild switch --impure --flake ".#<hostname>"
Linux/WSL: home-manager switch -b backup --extra-experimental-features "nix-command flakes" --impure --flake ".#<username>@<hostname>"
```

Requires `darwin-rebuild` (macOS) or `home-manager` (Linux/WSL), available after bootstrap.
If the command is not found, the script stops with an error. Immediately after the initial application, retry in a new terminal.

`bootstrap.sh` and `rebuild.sh` also pass the experimental features above and `--impure` to `nix eval` when reading the configuration.
On Linux/WSL, the experimental feature flags are also passed to Home Manager's `switch`.
Both scripts pass `DOTFILES_LOCAL_NIX` through; on macOS, `sudo --preserve-env=DOTFILES_LOCAL_NIX` passes it to the operation running with administrator privileges.

## Updating Inputs

Run updates inside the repository and choose one of the following according to your needs.
Both stop after updating `flake.lock`; neither automatically reapplies the configuration, runs GC, or creates commits.

| Command | Update scope |
| --- | --- |
| `make update-nixpkgs` | Nixpkgs only |
| `make update-all` | All inputs, including Home Manager, nix-darwin, and Fenix |

Nixpkgs-only updates do not update the revisions of Home Manager, nix-darwin, or Fenix themselves.
However, these inputs share Nixpkgs via `follows = "nixpkgs"` in [flake.nix](../flake.nix), so the update affects their Nixpkgs dependency.

For custom packages with versions pinned directly in the source, updating all inputs does not automatically change those pinned values.
The current example is Node.js `24.22.1` and its download hash in [pkgs/nodejs-bin.nix](../pkgs/nodejs-bin.nix).

The underlying commands for use without make are shown below.
As in the existing scripts, `nix-command` and `flakes` are explicitly enabled.

```bash
# Update Nixpkgs only
nix --extra-experimental-features nix-command \
  --extra-experimental-features flakes flake update nixpkgs
```

```bash
# Or update all inputs
nix --extra-experimental-features nix-command \
  --extra-experimental-features flakes flake update
```

After the chosen update, review the diff and apply the configuration if everything looks correct.

```bash
git diff -- flake.lock
make rebuild  # Without make, use ./scripts/rebuild.sh
```

If you use a different location, specify the same `DOTFILES_LOCAL_NIX` when reapplying ([examples](#localnix)).
