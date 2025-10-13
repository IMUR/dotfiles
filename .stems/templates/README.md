# Configuration Templates

This directory contains bootstrap templates for common configuration scenarios. Each template provides a starting point that follows the methodology principles.

## Available Templates

### repository/
Complete repository structure for a new configuration management repo.

```bash
# Usage
cp -r repository/ ~/my-new-config/
cd ~/my-new-config/
./init.sh
```

### node-config/
Template for configuring a new node in the cluster.

```bash
# Usage
cp -r node-config/ /tmp/new-node/
cd /tmp/new-node/
# Edit variables.yml with node specifics
./apply.sh <node-name>
```

### service/
Template for deploying a new containerized service.

```bash
# Usage
cp -r service/ ~/services/my-service/
cd ~/services/my-service/
# Edit docker-compose.yml and .env
docker compose up -d
```

## Using Templates

1. **Copy the template** to your working directory
2. **Review the README** in the template directory
3. **Customize variables** for your environment
4. **Run validation** before applying
5. **Document changes** you make

## Creating New Templates

When creating a new template:

1. Follow the methodology principles
2. Include comprehensive documentation
3. Add validation scripts
4. Provide example variables
5. Test on all node types

## Template Standards

All templates should include:

- `README.md` - Usage documentation
- `variables.yml` or `.env.template` - Configuration variables
- `validate.sh` - Validation script
- `apply.sh` - Application script (if applicable)
- Examples of common customizations
