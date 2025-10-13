# Core Principles for Small-Scale Cluster Management

## First-Order Principles

These principles are axiomatic - they define the fundamental nature of the system.

### P1: Unified System Identity
**The cluster operates as a single logical machine with multiple physical nodes.**

- No artificial separation between "personal" and "cluster" contexts
- Configuration management treats the cluster holistically
- User experience is unified across all nodes

### P2: Configuration as Data
**All configuration is data, not code.**

- Templates define structure
- Variables provide values
- Tools handle execution
- Humans handle decisions

### P3: Explicit Over Implicit
**All state, dependencies, and changes must be explicit and visible.**

- No hidden configuration
- No assumed prerequisites
- No magic behaviors
- Clear cause and effect

### P4: Safety Through Validation
**Changes are validated before application, always.**

- Validation is not optional
- Multiple validation stages catch different error classes
- Dry runs are the default
- Production changes require explicit approval

### P5: Hardware Determines Boundaries
**Physical differences set the limits of logical uniformity.**

- ARM vs x86 architectures create natural boundaries
- GPU availability affects service placement
- Memory/storage constraints guide resource allocation
- Network topology influences communication patterns

## Derived Principles

These principles follow logically from the first-order principles.

### D1: Templates Enable Parity (from P1 + P5)
**Templates with variables achieve uniformity despite hardware differences.**

```yaml
# Same template, different values
architecture: {{ .arch }}  # x86_64 or arm64
gpu_enabled: {{ .has_gpu }} # true or false
```

### D2: Version Control Is Truth (from P2 + P3)
**Git repository represents desired state completely.**

- Current state derives from repository
- Changes happen through commits
- History provides audit trail
- Branches enable experimentation

### D3: Idempotency Ensures Safety (from P4)
**All operations must be safely repeatable.**

```bash
# Running multiple times = same result
./apply-config.sh
./apply-config.sh  # Safe to run again
```

### D4: Tools Own Domains (from P2 + P3)
**Each tool has exclusive ownership of its configuration domain.**

| Domain | Tool | Scope |
|--------|------|-------|
| User Environment | Chezmoi | `~/.*` files |
| System Configuration | Ansible | `/etc/*`, systemd |
| Service Management | Docker | Containers, networks |
| Infrastructure Truth | SSOT scripts | Discovery, validation |

### D5: Automation Serves Humans (from P2 + P4)
**Automation enhances human decision-making, doesn't replace it.**

- Automation handles repetition
- Humans handle judgment
- Approval gates preserve control
- Documentation explains why

## Operational Principles

These principles guide daily operations and decision-making.

### O1: Fail Fast, Fail Safe
**Errors should be detected early and handled gracefully.**

```bash
# Validation pipeline stops at first error
syntax_check || exit 1
dependency_check || exit 1  
dry_run || exit 1
# Only then...
apply_changes
```

### O2: Progressive Disclosure
**Complexity reveals itself only when needed.**

- Simple tasks remain simple
- Advanced features available but not required
- Defaults handle common cases
- Documentation layers from quick to comprehensive

### O3: Local Development, Global Thinking
**Changes tested locally, applied globally.**

```bash
# Local test
chezmoi diff --source-path ./dotfiles

# Global apply
for node in crtr prtr drtr; do
    ssh $node chezmoi apply
done
```

### O4: Observability Over Debugging
**Systems should explain themselves without investigation.**

- Validation output is comprehensive
- Changes shown before application
- Logs capture all activities
- State is always discoverable

### O5: Recovery Over Prevention
**Fast rollback is better than perfect prevention.**

- Git provides instant rollback
- Previous states always recoverable
- Partial failures don't cascade
- Learn from failures, don't fear them

## Decision Principles

These principles guide architectural and implementation choices.

### Choose Boring Technology
**Proven, stable tools over cutting-edge solutions.**

- Bash over exotic shells
- Docker over latest orchestrator
- SSH over complex protocols
- Text files over databases

### Optimize for Understanding
**Clarity beats cleverness every time.**

```bash
# Clear
if [ -f "$config_file" ]; then
    apply_config "$config_file"
fi

# Clever but unclear
[ -f "$config_file" ] && apply_config "$config_file"
```

### Design for Day Two
**Consider maintenance from the beginning.**

- How will this be updated?
- How will this be debugged?
- How will this be documented?
- How will this be handed off?

### Embrace Constraints
**Limitations guide better design.**

- 3 nodes means simple coordination
- No auto-scaling means predictable resources
- Manual approval means careful changes
- Small scale means direct access

## Anti-Principles

These are explicitly rejected approaches.

### ❌ Abstraction for Abstraction's Sake
- Don't hide necessary complexity
- Don't create meta-configurations
- Don't build frameworks for single use

### ❌ Premature Optimization
- Don't optimize before measuring
- Don't cache before needing
- Don't distribute before scaling

### ❌ Configuration by Convention
- Don't rely on implicit defaults
- Don't assume standard locations
- Don't depend on naming patterns

### ❌ Silent Failure
- Don't swallow errors
- Don't continue after failures
- Don't hide problems

### ❌ Permanent Temporary Solutions
- Don't accept "just for now" configs
- Don't leave TODOs indefinitely
- Don't bypass established patterns

## Principle Hierarchy

When principles conflict, this hierarchy resolves disputes:

1. **Safety** - Validation before application
2. **Clarity** - Explicit over implicit
3. **Simplicity** - Boring over clever
4. **Consistency** - Patterns over exceptions
5. **Efficiency** - Optimization last

## Application Examples

### Example 1: New Service Deployment
```
Principles Applied:
- P4: Validate compose file syntax
- D4: Docker owns service domain
- O1: Fail fast on configuration errors
- O3: Test on single node first

Process:
1. Write docker-compose.yml
2. Validate: docker compose config
3. Test: docker compose up (single node)
4. Deploy: Apply to all nodes
5. Verify: Health checks pass
```

### Example 2: Shell Configuration Update
```
Principles Applied:
- P1: Unified experience across nodes
- D1: Templates handle differences
- O4: Show changes clearly
- D3: Idempotent application

Process:
1. Edit dotfiles/dot_bashrc.tmpl
2. Preview: chezmoi diff
3. Test: chezmoi apply (local)
4. Deploy: git push + pull on nodes
5. Verify: Shell behaves correctly
```

## Living Principles

These principles evolve through experience:

- Regular reviews identify gaps
- Failures generate new principles
- Success patterns become principles
- Community feedback shapes principles

**Remember:** Principles guide but don't dictate. Use judgment, document exceptions, learn continuously.
