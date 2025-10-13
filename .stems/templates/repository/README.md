# Repository Bootstrap Template

This template provides a complete structure for a new configuration management repository following the IaC/GitOps methodology.

## Structure

```
.
├── README.md           # Repository documentation
├── .gitignore          # Git ignore rules
├── dotfiles/           # User configurations (Chezmoi)
├── ansible/            # System configurations
├── services/           # Service deployments
├── scripts/            # Automation scripts
├── docs/               # Documentation
└── .github/            # GitHub Actions (optional)
```

## Quick Start

1. **Initialize the repository:**
   ```bash
   ./init.sh
   ```

2. **Configure for your environment:**
   ```bash
   # Edit configuration
   vim config/cluster.yml
   
   # Set node information
   vim ansible/inventory/hosts.yml
   ```

3. **Run initial validation:**
   ```bash
   ./scripts/validation/validate-all.sh
   ```

## Customization Points

### Cluster Configuration
Edit `config/cluster.yml`:
```yaml
cluster:
  name: my-cluster
  nodes:
    - name: node1
      ip: 192.168.1.10
      role: primary
```

### Tool Selection
The template assumes Chezmoi + Ansible + Docker. To use different tools:

1. Replace `dotfiles/` with your user config tool
2. Replace `ansible/` with your system config tool  
3. Replace `services/` with your service management approach

### Validation Pipeline
Modify `scripts/validation/` scripts to match your tools and requirements.

## What's Included

### Pre-configured Files

- **`.gitignore`** - Sensible defaults for configuration repos
- **`.editorconfig`** - Consistent formatting rules
- **`LICENSE`** - MIT license (change as needed)
- **`CONTRIBUTING.md`** - Contribution guidelines

### Template Scripts

- **`init.sh`** - Repository initialization
- **`scripts/validation/validate-all.sh`** - Complete validation
- **`scripts/deploy.sh`** - Deployment automation
- **`scripts/rollback.sh`** - Emergency rollback

### Documentation Templates

- **`docs/ARCHITECTURE.md`** - System architecture
- **`docs/RUNBOOK.md`** - Operational procedures
- **`docs/TROUBLESHOOTING.md`** - Common issues

## Next Steps

1. Review and customize the structure
2. Add your specific configurations
3. Set up your validation pipeline
4. Document your customizations
5. Commit and start managing!

## Notes

- This template follows the principles in `../../METHODOLOGY.md`
- Patterns are based on `../../CLUSTER-PATTERNS.md`
- Lifecycle follows `../../LIFECYCLE.md`

Modify freely to match your specific needs!
