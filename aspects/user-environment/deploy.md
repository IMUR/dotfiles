# User Environment Aspect - Deployment Strategy

## Deployment

### Phase 1: Install Chezmoi
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

### Phase 2: Initialize Dotfiles
```bash
# From existing repo
chezmoi init <dotfiles-repo-url>

# Or from /cluster-nas backup
chezmoi init /cluster-nas/backups/dotfiles

# Preview changes
chezmoi diff

# Apply
chezmoi apply
```

### Phase 3: Install User Tools
```bash
# Package-managed tools
sudo apt install -y eza bat fd-find ripgrep

# Standalone tools
curl -sS https://starship.rs/install.sh | sh
# Atuin installed separately (see systemd aspect)
```

### Phase 4: Create Directory Structure
```bash
mkdir -p ~/.local/{bin,share}
mkdir -p ~/.config
mkdir -p ~/Projects ~/workspace
```

### Phase 5: Set Default Shell
```bash
chsh -s /bin/zsh
```

## Implementation

User environment is defined by:
- Dotfiles in chezmoi (versioned)
- ~/.local/bin for user scripts
- ~/.config for application configs
- Zsh as default shell

## Completion

```bash
# Chezmoi initialized
chezmoi status

# Dotfiles applied
ls -la ~/ | grep -E '\.zshrc|\.bashrc|\.gitconfig'

# Tools installed
which eza bat fd rg zoxide starship

# Directories exist
ls -ld ~/.local/bin ~/.config ~/Projects ~/workspace

# Default shell
echo $SHELL  # Should be /bin/zsh
```

## Persistence

- **Dotfiles**: Managed by chezmoi, backed by git
- **Tools**: Installed via APT (persist) or manual (document in aspect.yml)
- **Directories**: Created once, persist across reboots
- **Shell**: Set in /etc/passwd, persists

To restore user environment on new system:
```bash
chezmoi init <repo>
chezmoi apply
# Reinstall tools from aspect.yml
```

## Growth

### Add New Dotfile
```bash
# Add to chezmoi
chezmoi add ~/.config/newapp/config.toml

# Edit as needed
chezmoi edit ~/.config/newapp/config.toml

# Commit to dotfiles repo
chezmoi cd
git add .
git commit -m "Add newapp config"
git push
```

### Add User Tool
```bash
# Install tool
wget <tool-url> -O ~/.local/bin/newtool
chmod +x ~/.local/bin/newtool

# Document in aspect.yml
# Add to tools.standalone list
```

### Modify Shell Config
```bash
# Edit source
chezmoi edit ~/.zshrc

# Apply
chezmoi apply

# Reload shell
source ~/.zshrc
```
