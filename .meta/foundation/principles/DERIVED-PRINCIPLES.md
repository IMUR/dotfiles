# Derived Principles

## From: System Identity

- Core infrastructure spans all 3 nodes as single system
- Infrastructure decisions apply uniformly unless explicitly node-specific
- Documentation references "the cluster" as singular entity

## From: Configuration Organization by Aspect

- **Aspect: Cluster UX Baseline** → `colab-config/dotfiles/` (Chezmoi)
  - User-level configs identical across all nodes
  - Shell customizations, prompts, aliases
  - Enforces operational parity

- **Aspect: Node-Specific Personality** → `<user>-config/` pattern
  - Local variations respecting baseline parity
  - Node-specific tooling, workflows, dev environments
  - Does not pollute cluster baseline

- **Aspect: System-Level Automation** → `colab-config/ansible/`
  - Requires approval before execution
  - Changes system state across nodes

- **Aspect: Service Orchestration** → `colab-config/services/`
  - Container-based services
  - Declarative deployment

## From: UX Parity

- Shell configuration changes propagate to all nodes via Chezmoi
- Terminal behavior must be predictable regardless of entry point
- Custom tooling available cluster-wide goes in colab-config
- Personal experiments stay in user-config until promoted

**Examples:**
- Unified shell history (atuin) syncs across all nodes - identical search experience
- Cluster navigation functions (tmux helpers) available identically on all nodes
- Shell RC files source same functions, aliases, and integrations

## From: Hardware Realism

- Chezmoi templates use `{{ .chezmoi.hostname }}` conditionals for hardware-specific configs
- Architecture-specific packages managed per-node (ARM64 on crtr, x86_64 on prtr/drtr)
- GPU-related configs only on nodes with GPUs (prtr: 4x, drtr: 1x)
- When best practice conflicts with uniformity, best practice wins
- Hardware constraints are documented, not worked around artificially

## From: Scope Boundaries

- **Decision: Would this config be identical on all 3 nodes?**
  - Yes → `colab-config/dotfiles/`
  - No, but hardware-specific → `colab-config/dotfiles/` with Chezmoi conditionals
  - No, personal/experimental → `<user>-config/`

- **Decision: Does this modify system state?**
  - Yes → `ansible/` with approval gates
  - No → Direct tool (Chezmoi, Docker Compose)

- **Decision: Is this a service deployment?**
  - Yes → `services/` with Docker Compose
  - No → Check other aspects

## From: Node Independence

### SSH Infrastructure

- **Two-tier key system:**
  - Inter-node keys (`id_ed25519`) - For node-to-node SSH
  - Self keys (`id_ed25519_self`) - For node-to-self SSH (loopback)
  - Separation allows distinct authorization policies and easier key rotation

- **Key sovereignty:**
  - Each node generates its own key pairs
  - Private keys never leave their origin node
  - Public keys are collected and distributed centrally
  - No shared private keys across nodes

- **SSH config templating:**
  - Node-aware via Chezmoi: `{{ .chezmoi.hostname }}`
  - Self-SSH uses `id_ed25519_self` on current node
  - Inter-node SSH uses `id_ed25519` to other nodes
  - Single config template adapts to each node's context

- **Authorized keys uniformity:**
  - All nodes maintain identical structure (6 keys)
  - Only difference: node's own self-key vs. inter-node key
  - Enforces predictable access matrix
  - Canonical specification in `docs/ssh-spec.md`

### Connection Optimization

- **ControlMaster multiplexing:**
  - Shares single SSH connection across multiple sessions
  - Socket directory: `~/.ssh/sockets/`
  - Persists for 10 minutes after last use
  - Critical for parallel cluster operations, repeated SSH

- **Performance over security theater:**
  - Connection reuse is safe within trusted cluster
  - Reduces authentication overhead
  - Enables fast parallel operations

- **Enhanced SSH tools:**
  - Resilient connections (survive network interruptions)
  - Parallel cluster management (execute on multiple nodes simultaneously)
  - All respect existing SSH infrastructure (keys, config, ControlMaster)
