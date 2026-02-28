# key links related to using a dotfiles GitHub repo

## Core Setup & Initialization

- [Quick start](https://www.chezmoi.io/quick-start/) - Complete guide for starting with GitHub repos
- [Setup](https://www.chezmoi.io/user-guide/setup/) - Detailed setup instructions for hosted repos
- [Daily operations](https://www.chezmoi.io/user-guide/daily-operations/) - Managing your GitHub repo day-to-day
- [Command overview](https://www.chezmoi.io/user-guide/command-overview/) - All commands for repo management

## Commands Reference

- [init](https://www.chezmoi.io/reference/commands/init/) - Initialize from a GitHub repo
- [update](https://www.chezmoi.io/reference/commands/update/) - Pull and apply changes from repo
- [git](https://www.chezmoi.io/reference/commands/git/) - Run git commands in source directory
- [cd](https://www.chezmoi.io/reference/commands/cd/) - Open shell in source directory

## Configuration

- [Configuration file](https://www.chezmoi.io/reference/configuration-file/) - Config options including auto-commit/push
- [Hooks](https://www.chezmoi.io/reference/configuration-file/hooks/) - Pre/post hooks for git operations

## GitHub-Specific Features

- [GitHub functions](https://www.chezmoi.io/reference/templates/github-functions/) - Template functions for GitHub API
  - [gitHubKeys](https://www.chezmoi.io/reference/templates/github-functions/gitHubKeys/)
  - [gitHubLatestRelease](https://www.chezmoi.io/reference/templates/github-functions/gitHubLatestRelease/)
  - [gitHubLatestReleaseAssetURL](https://www.chezmoi.io/reference/templates/github-functions/gitHubLatestReleaseAssetURL/)

## Examples & Inspiration

- [twpayne/dotfiles](https://github.com/twpayne/dotfiles) - Author of chezmoi
- [posquit0/dotfiles](https://github.com/posquit0/dotfiles)
- [felipecrs/dotfiles](https://github.com/felipecrs/dotfiles)
- [kutsan/dotfiles](https://github.com/kutsan/dotfiles)
- [renemarc/dotfiles](https://github.com/renemarc/dotfiles)
- [g6ai/dotfiles](https://github.com/g6ai/dotfiles)

## FAQ & Troubleshooting

- [Usage FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/)
- [Troubleshooting](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/)

## Reference Tree

dotfiles/
├── .chezmoiroot              # Point chezmoi at ./home as the source root
├── .editorconfig
├── .gitignore
├── README.md

├── home/                     # Actual chezmoi source state (dotfiles, templates)
│   ├── .chezmoi.yaml.tmpl    # Chezmoi config, templatized per host/user
│   ├── .chezmoiignore        # Global ignore rules (backups, caches, etc.)
│   ├── .chezmoiexternal.yaml # External resources (git repos, archives, etc.)

│   ├── dot_gitconfig.tmpl    # ~/.gitconfig (templated: name/email, signing)
│   ├── dot_gitconfig.local   # ~/.gitconfig.local (untracked, machine-specific)
│   ├── dot_zshrc.tmpl        # ~/.zshrc (templated for OS, host, features)
│   ├── dot_zprofile
│   ├── dot_bashrc.tmpl
│   ├── dot_bash_profile
│   ├── dot_profile
│   ├── dot_inputrc

│   ├── dot_config/           # XDG config root → ~/.config
│   │   ├── git/
│   │   │   ├── config.tmpl   # ~/.config/git/config
│   │   │   └── ignore
│   │   ├── nvim/
│   │   │   ├── init.lua.tmpl
│   │   │   └── lua/
│   │   │       └── plugins.lua.tmpl
│   │   ├── zsh/
│   │   │   └── zshrc.d/      # Modular Zsh config, sourced from dot_zshrc
│   │   ├── tmux/
│   │   │   └── tmux.conf.tmpl
│   │   ├── alacritty/
│   │   │   └── alacritty.toml.tmpl
│   │   ├── kitty/
│   │   │   └── kitty.conf.tmpl
│   │   └── starship.toml.tmpl

│   ├── dot_local/
│   │   ├── bin/
│   │   │   ├── ex_bin_fzf         # ~/.local/bin/fzf
│   │   │   ├── ex_bin_zoxide      # managed as regular files
│   │   │   └── script-example.tmpl
│   │   └── share/
│   │       └── templates/         # Helper templates, snippets, etc.

│   ├── private_dot_ssh/       # ~/.ssh (encrypted / private files)
│   │   ├── private_id_ed25519        # Encrypted with age/gpg
│   │   ├── private_id_ed25519.pub
│   │   └── config.tmpl              # Uses secrets from password manager

│   ├── private_dot_config/    # Private configs (tokens, API keys, etc.)
│   │   └── gh/
│   │       └── hosts.yml      # GitHub CLI auth

│   ├── dot_config/chezmoi/
│   │   ├── chezmoi.toml.tmpl  # Tool-specific chezmoi config if desired
│   │   └── scripts/           # On-apply hooks, custom actions
│   │       ├── run_once_before-all.sh.tmpl
│   │       └── run_after-nvim-plugins.sh

│   ├── run_once_install-packages.sh.tmpl   # First-time bootstrap
│   ├── run_onchange_refresh-shell.sh       # Triggered when shell config changes
│   └── run_after_fonts-installed.sh

├── install/                  # Environment bootstrap / meta-scripts (not source)
│   ├── install.sh            # Entry point: curl | sh or manual
│   ├── macos.sh              # macOS-specific: brew, defaults, etc.
│   ├── linux.sh              # Linux-specific: apt/dnf/pacman, system tweaks
│   ├── wsl.sh                # WSL-specific adjustments
│   └── post-install.md       # Manual follow-up steps documentation

├── tests/                    # Optional: testable configuration
│   ├── shell/
│   │   └── test_zshrc.bats   # E.g., Bats tests for expected aliases/options
│   ├── nvim/
│   │   └── test_init.lua
│   └── ci/
│       └── github-actions.yml.tmpl  # CI to validate repo builds & applies

└── docs/                     # Extra documentation / design notes
    ├── ARCHITECTURE.md       # Rationale for layout, OS handling, etc.
    ├── MACHINES.md           # Hostnames, tags, and roles
    └── SECRETS.md            # How secrets are stored (age, 1Password, etc.)
