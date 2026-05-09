# dotfiles

[English](README.md) | [日本語](README.ja.md)

Personal dotfiles for Apple Silicon macOS and x86_64 Linux / WSL.

This repository uses Nix flakes, nix-darwin on macOS, and Home Manager on both macOS and Linux.

## Initial Setup

### macOS

#### 1. Install Nix

Install Nix first if it is not already installed.

Run the Nix modern installer with flakes enabled.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

The installer may ask for confirmation before making changes to the system.
When prompted with `Proceed? ([Y]es/[n]o/[e]xplain)`, press Enter or type `y`.

After installation, restart your terminal.

Check that Nix is available.

```bash
nix --version
```

#### 2. Clone this repository

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### 3. Configure Git

`./init-local.sh` reads the global Git user name and email and writes them to `local.nix`.

Check the current values.

```bash
git config --global user.name
git config --global user.email
```

If either value is not configured yet, configure it first.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

#### 4. Create `local.nix`

Generate the machine-specific configuration.

```bash
./init-local.sh
```

By default, it is created at the following location.

```text
~/.config/dotfiles/local.nix
```

For Apple Silicon macOS, the generated content looks like this.

```nix
{
  username = "your-macos-username";
  hostname = "your-mac";

  platform = "darwin";
  system = "aarch64-darwin";
  homeDirectory = "/Users/your-macos-username";

  git = {
    name = "Your Name";
    email = "you@example.com";
  };
}
```

`local.nix` is machine-specific configuration. Do not commit it to Git.

If you want to create it in a different location, specify `DOTFILES_LOCAL_NIX` when running the script.

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./init-local.sh
```

#### 5. Apply nix-darwin for the first time

Run the initial nix-darwin activation.

```bash
./bootstrap.sh
```

This applies the nix-darwin system configuration and Home Manager user configuration.

Use `./rebuild.sh` for daily updates from this point onward.

### Linux / WSL

#### 1. Install Nix

Install Nix first if it is not already installed.

Run the Nix modern installer with flakes enabled.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

After installation, restart your shell.

Check that Nix is available.

```bash
nix --version
```

#### 2. Clone this repository

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### 3. Configure Git

`./init-local.sh` reads the global Git user name and email and writes them to `local.nix`.

Check the current values.

```bash
git config --global user.name
git config --global user.email
```

If either value is not configured yet, configure it first.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

#### 4. Create `local.nix`

Generate the machine-specific configuration.

```bash
./init-local.sh
```

For x86_64 Linux / WSL, the generated content looks like this.

```nix
{
  username = "your-linux-username";

  # This value depends on your Linux host or WSL distribution.
  # Examples: "ubuntu", "debian", "arch", "my-linux"
  hostname = "ubuntu";

  platform = "linux";
  system = "x86_64-linux";
  homeDirectory = "/home/your-linux-username";

  isWsl = true;

  git = {
    name = "Your Name";
    email = "you@example.com";
  };
}
```

`isWsl = true;` is generated only when WSL is detected.

The Linux output name has the following format.

```text
homeConfigurations.<username>@<hostname>
```

#### 5. Apply Home Manager for the first time

Run the initial Home Manager activation.

```bash
./bootstrap.sh
```

This applies the Linux / WSL user configuration using the Home Manager flake input.

Use `./rebuild.sh` for daily updates from this point onward.

#### 6. Make zsh the login shell

On Linux / WSL, Home Manager creates the zsh configuration.

However, the login shell itself may not automatically change to zsh.

After `./bootstrap.sh`, run the following once.

```bash
ZSH_PATH="$(command -v zsh)"

if [ -z "$ZSH_PATH" ]; then
  echo "zsh not found"
  exit 1
fi

if ! grep -qxF "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

chsh -s "$ZSH_PATH"
```

For WSL, restart WSL from the PowerShell side.

```powershell
wsl --shutdown
```

Then reopen Linux / WSL and check.

```bash
echo "$SHELL"
```

It is OK if `zsh` is included.

Use `./rebuild.sh` for daily updates from this point onward.

## Daily Usage

Apply configuration changes.

```bash
cd ~/dotfiles
./rebuild.sh
```

`./rebuild.sh` reads `local.nix` and runs the following according to `platform`.

```text
macOS:      darwin-rebuild switch --impure --flake ".#<hostname>"
Linux/WSL: home-manager switch -b backup --impure --flake ".#<username>@<hostname>"
```

Update flake inputs.

```bash
cd ~/dotfiles
nix flake update
./rebuild.sh
```

If `local.nix` is in a non-default location, specify the same path for daily commands.

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./rebuild.sh
```

## Scripts

### `init-local.sh`

Generates the machine-specific `local.nix`.

It detects platform, system, username, hostname, home directory, WSL status, and global Git user information.

```bash
./init-local.sh
```

Use `--force` to overwrite an existing generated file.

```bash
./init-local.sh --force
```

### `bootstrap.sh`

For initial activation.

On macOS, it bootstraps using the nix-darwin flake input. On Linux / WSL, it bootstraps using the Home Manager flake input.

```bash
./bootstrap.sh
```

### `rebuild.sh`

For daily rebuilds after editing configuration.

On macOS, this assumes `darwin-rebuild` is available after bootstrap. On Linux / WSL, this assumes `home-manager` is available after bootstrap.

```bash
./rebuild.sh
```

## Structure

```text
.
├── README.md                 # English README
├── README.ja.md              # Japanese README
├── flake.nix                 # flake entry point
├── flake.lock                # Locked flake inputs
├── local.nix.example         # Example machine-specific configuration
├── init-local.sh             # Generate local.nix
├── bootstrap.sh              # Initial activation
├── rebuild.sh                # Daily rebuild
├── .gitignore
├── hosts/
│   └── darwin/
│       └── default.nix       # nix-darwin system configuration
├── home/
│   ├── common/               # Common Home Manager modules
│   │   ├── default.nix       # Common Home Manager entry point
│   │   ├── packages.nix      # Common packages and development tools
│   │   ├── git.nix           # Git
│   │   ├── shell.nix         # Zsh
│   │   └── prompt.nix        # Starship
│   ├── darwin/               # macOS-specific Home Manager modules
│   │   ├── default.nix       # macOS Home Manager entry point
│   │   ├── packages.nix      # macOS packages
│   │   ├── aerospace.nix     # AeroSpace
│   │   └── terminals.nix     # Ghostty config link
│   └── linux/                # Linux / WSL Home Manager modules
│       ├── default.nix       # Linux Home Manager entry point
│       ├── packages.nix      # Linux packages
│       ├── session.nix       # Linux session variables
│       └── wsl.nix           # WSL
└── configs/
    ├── ghostty/
    │   └── config.ghostty    # Ghostty config
    └── aerospace/
        └── aerospace.toml    # AeroSpace config
```

## Requirements

### macOS

- Apple Silicon Mac
- Git
- Nix

### Linux / WSL

- x86_64 Linux or WSL
- Git
- Nix
