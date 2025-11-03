# Dotfiles Configuration

The configuration files are managed with [GNU Stow].

## Quick Setup

### macOS

For shell and editor configurations on macOS:

```console
$ git clone git@github.com:ptravers/configs.git
$ cd configs
$ ./setup_macos.sh
```

Prerequisites:
- Homebrew must be installed ([brew.sh](https://brew.sh))

This will:
- Install essential packages (fish, helix, jj, stow, tmux, fzf, etc.)
- Back up existing dotfiles
- Use stow to symlink shell and editor configurations
- Set up fish as the default shell
- Install NVM and pnpm

### Ubuntu/Debian

For a fresh Ubuntu installation, use the automated setup script:

```console
$ git clone git@github.com:ptravers/configs.git
$ cd configs
$ ./setup.sh
```

This will:
- Install essential packages (fish, helix, jj, stow, tmux, fzf, etc.)
- Back up existing dotfiles
- Use stow to symlink all configuration groups
- Set up fish as the default shell
- Install NVM and pnpm

## Manual Setup

Each top-level directory represents a "group" of configs, and you can
"install" (by symlinking) the configs of a group using

```console
$ stow -Sv <group>
```

You can use `-n` to just show what it _would_ install.

Stow has a bunch of [shortcomings], but I haven't bothered to move to
anything else yet. In theory, the directory layout should be mostly
compatible with other tools like [chezmoi] that you may enjoy more,
though I have not tried them myself.

[GNU Stow]: https://www.gnu.org/software/stow/
[shortcomings]: https://github.com/aspiers/stow/issues/33
[chezmoi]: https://www.chezmoi.io/
