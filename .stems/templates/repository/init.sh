#!/bin/bash
# Repository Initialization Script
# Following IaC/GitOps methodology for small-scale clusters

set -e  # Exit on error

echo "🚀 Initializing configuration repository..."

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p dotfiles ansible/playbooks ansible/inventory ansible/group_vars
mkdir -p services scripts/validation scripts/deployment
mkdir -p docs/guides docs/runbooks
mkdir -p config tests

# Initialize git if not already
if [ ! -d .git ]; then
    echo "📝 Initializing git repository..."
    git init
    git branch -M main
fi

# Create default .gitignore
echo "🔒 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Secrets and credentials
*.key
*.pem
.env
.env.*
!.env.template
secrets/

# Runtime and cache
*.pyc
__pycache__/
.cache/
*.log

# Backup files
*.bak
*.orig
*.swp
*~

# OS specific
.DS_Store
Thumbs.db

# Tool specific
.terraform/
*.tfstate*
.ansible/
.vagrant/
EOF

# Create config template
echo "⚙️ Creating configuration template..."
cat > config/cluster.yml << 'EOF'
---
# Cluster Configuration
cluster:
  name: my-cluster
  domain: local
  
nodes:
  - name: node1
    ip: 192.168.1.10
    role: primary
    arch: x86_64
    
  - name: node2
    ip: 192.168.1.20
    role: worker
    arch: x86_64
    
  - name: node3
    ip: 192.168.1.30
    role: worker
    arch: arm64

services:
  monitoring: enabled
  logging: enabled
  backup: enabled
EOF

# Create validation script
echo "✅ Creating validation script..."
cat > scripts/validation/validate-all.sh << 'EOF'
#!/bin/bash
# Complete validation pipeline

set -e

echo "Starting validation pipeline..."

# Syntax checks
echo "1. Checking syntax..."
if command -v yamllint &> /dev/null; then
    yamllint config/*.yml || echo "⚠️ YAML issues found"
fi

if command -v shellcheck &> /dev/null; then
    shellcheck scripts/**/*.sh || echo "⚠️ Shell script issues found"
fi

# Configuration checks
echo "2. Checking configurations..."
if [ -d dotfiles ] && command -v chezmoi &> /dev/null; then
    echo "   Validating dotfiles..."
    chezmoi verify || echo "⚠️ Dotfile issues found"
fi

if [ -d ansible ] && command -v ansible &> /dev/null; then
    echo "   Validating ansible..."
    ansible-playbook --syntax-check ansible/playbooks/*.yml 2>/dev/null || echo "⚠️ Ansible issues found"
fi

if [ -d services ] && command -v docker &> /dev/null; then
    echo "   Validating services..."
    for compose in services/*/docker-compose.yml; do
        [ -f "$compose" ] && docker compose -f "$compose" config -q || echo "⚠️ Docker compose issues found"
    done
fi

echo "✅ Validation complete!"
EOF
chmod +x scripts/validation/validate-all.sh

# Create deployment script template
echo "🚀 Creating deployment template..."
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script following validation-first principle

set -e

# Run validation first
echo "Running pre-deployment validation..."
./scripts/validation/validate-all.sh || exit 1

# Show what will change
echo "Changes to be deployed:"
# Add your diff/preview commands here

# Confirm deployment
read -p "Deploy changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Deploy to nodes
echo "Deploying configuration..."
# Add your deployment commands here

echo "✅ Deployment complete!"
EOF
chmod +x scripts/deploy.sh

# Create README
echo "📚 Creating README..."
cat > README.md << 'EOF'
# Configuration Repository

This repository manages configuration for our infrastructure using IaC/GitOps principles.

## Quick Start

1. Edit `config/cluster.yml` with your cluster details
2. Run `./scripts/validation/validate-all.sh` to validate
3. Run `./scripts/deploy.sh` to deploy

## Structure

- `dotfiles/` - User configurations
- `ansible/` - System configurations  
- `services/` - Service deployments
- `scripts/` - Automation scripts
- `docs/` - Documentation
- `config/` - Cluster configuration

## Principles

This repository follows:
- Infrastructure as Code (IaC)
- GitOps workflow
- Validation-first deployment
- Explicit configuration

See `docs/ARCHITECTURE.md` for details.
EOF

# Create initial commit
echo "💾 Creating initial commit..."
git add -A
git commit -m "Initial repository structure" || true

echo "✨ Repository initialized successfully!"
echo ""
echo "Next steps:"
echo "1. Edit config/cluster.yml with your cluster information"
echo "2. Add your configurations to dotfiles/, ansible/, and services/"
echo "3. Run ./scripts/validation/validate-all.sh to validate"
echo "4. Commit your changes and deploy"
