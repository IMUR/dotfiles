# Node Configuration Template

Template for setting up a new node in your cluster.

## What This Does

Configures a new node with:
- Base system packages
- User environment (shell, dotfiles)
- SSH access
- Docker runtime
- Monitoring agent
- Standard directory structure

## Prerequisites

- SSH access to the target node
- sudo privileges on the target node
- Configuration management tools installed locally

## Usage

1. **Edit variables for your node:**
   ```bash
   vim variables.yml
   ```

2. **Run validation:**
   ```bash
   ./validate.sh
   ```

3. **Apply configuration:**
   ```bash
   ./apply.sh <node-name>
   ```

## Configuration Files

### variables.yml
Node-specific variables:
```yaml
node:
  name: mynode
  ip: 192.168.1.100
  role: worker
  arch: x86_64
  
user:
  name: trtr
  shell: /bin/zsh
  
services:
  docker: true
  monitoring: true
```

### base-packages.txt
List of packages to install on all nodes.

### node-setup.sh
Main setup script that configures the node.

## Customization

### Adding Packages
Edit `base-packages.txt` to add system packages.

### User Configuration  
Add dotfiles to `dotfiles/` directory.

### Service Configuration
Add service configs to `services/` directory.

## Validation

The template includes validation for:
- Network connectivity
- SSH access
- Sudo privileges
- Package availability
- Disk space

## Rollback

If configuration fails:
```bash
./rollback.sh <node-name>
```

This will restore the previous configuration state.
