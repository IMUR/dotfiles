# AI Agent Operational Boundaries

**Purpose:** Define concise operational boundaries for AI agents working in this repository

**Last Updated:** 

## Repository Context

- **Type:** 
- **Purpose:** 
- **Scope:** Single repository

## Safety Rules

### Forbidden Actions

AI agents must NEVER:

- Delete files (archive instead)
- Modify system files directly without appropriate tools
- Commit secrets or credentials
- Force push to main/master branches


### Requires Human Approval

AI agents must get approval before:

- System-level changes (Ansible playbooks)
- Service deployments affecting production
- Git destructive operations (hard reset, force push)


## Operational Boundaries

### Permitted Actions

AI can autonomously:

- Read and analyze code/configuration files
- Edit templates in dotfiles/
- Run validation and syntax checks
- Generate documentation
- Suggest improvements


## Directory-Specific Context

For detailed operational context in specific directories, see:

- **dotfiles/**: `.agent-context.json` - User environment configuration (Chezmoi)
- **ansible/**: `.agent-context.json` - System automation (requires approval)
- **services/**: `.agent-context.json` - Service management (Docker)
- **scripts/**: `.agent-context.json` - Automation scripts

## Validation Requirements

Before committing changes, AI should:

1. Run appropriate validation commands (shellcheck, yamllint, etc.)
2. Execute dry-run/preview commands where available
3. Verify syntax with tool-specific validators
4. Review generated diffs

---

**Note:** This file was auto-generated from repository analysis.

**Schema:** `.meta/foundation/schemas/agents-md.schema.json`
**Generator:** `.meta/whitelists/generate-meta-files.sh`
