# Infrastructure-as-Code Methodology for Small-Scale Clusters

## Overview

This methodology adapts proven Infrastructure-as-Code (IaC) and GitOps principles specifically for small-scale cluster configuration management. It's designed for systems like the Co-lab 3-node cluster where enterprise-scale complexity isn't needed, but professional-grade practices are essential.

## Core Philosophy

### The Five Pillars

1. **Declarative Configuration**
   - Define *what* the system should be, not *how* to get there
   - Templates describe desired state, tools handle reconciliation
   - Configuration is data, not scripts

2. **Git as Single Source of Truth**
   - All configuration lives in version control
   - Changes are tracked, reviewed, and reversible
   - History provides natural audit trail and rollback capability

3. **Validation-First Deployment**
   - Nothing touches production without validation
   - Multiple validation gates: syntax → simulation → approval → apply
   - Fail fast, fail safe, fail informatively

4. **Environment Parity Through Templates**
   - Identical experiences across all nodes where possible
   - Hardware differences handled through template variables
   - Node-specific variations explicit, not accidental

5. **Separation of Concerns by Tool**
   - Each tool owns its domain completely
   - Clear boundaries: user config (Chezmoi) vs system config (Ansible) vs services (Docker)
   - No tool overlap, no configuration confusion

## The Configuration Lifecycle

### Phase 1: Declaration
```
Developer → Templates → Repository
```
- Configuration expressed as templates
- Variables for node-specific values
- Documentation embedded in configuration

### Phase 2: Validation
```
Templates → Syntax Check → Dry Run → Diff
```
- Automated syntax validation
- Simulation of changes without impact
- Clear visualization of what will change

### Phase 3: Approval
```
Diff → Human Review → Approval Gate
```
- Explicit approval for system-level changes
- Automatic approval for safe operations
- Clear escalation paths

### Phase 4: Application
```
Approved Changes → Apply → Verify
```
- Idempotent application (safe to retry)
- Post-application verification
- Rollback capability always available

### Phase 5: Reconciliation
```
Current State → Desired State → Convergence
```
- Regular validation against desired state
- Drift detection and alerting
- Automated or guided remediation

## Implementation Patterns

### Pattern 1: Template-Variable Separation
```yaml
# Template (what)
hostname: {{ .hostname }}
ip_address: {{ .node_ip }}

# Variables (values)
hostname: cooperator
node_ip: 192.168.254.10
```

### Pattern 2: Multi-Stage Validation
```bash
# Stage 1: Syntax
chezmoi execute-template < template.tmpl

# Stage 2: Simulation  
chezmoi diff

# Stage 3: Approval
read -p "Apply changes? " && chezmoi apply
```

### Pattern 3: Tool Domain Boundaries
```
User Space:
  ~/.bashrc → Chezmoi
  ~/.ssh/config → Chezmoi
  
System Space:
  /etc/hosts → Ansible
  /etc/systemd/ → Ansible
  
Service Space:
  containers → Docker Compose
  volumes → Docker Compose
```

### Pattern 4: Safety Gates
```yaml
validation:
  automatic:
    - syntax_check
    - dependency_check
    - dry_run
  manual:
    - system_changes
    - service_deployment
    - network_modification
```

## Operational Principles

### 1. Idempotency
Every operation must be safely repeatable:
- Running twice produces same result
- No incremental side effects
- Clear success/failure states

### 2. Immutability
Configuration is replaced, not edited:
- Templates generate fresh configs
- No in-place modifications
- Clean state transitions

### 3. Observability
All operations must be visible:
- Validation output is comprehensive
- Changes are clearly shown
- Logs capture all activities

### 4. Reversibility
Every change can be undone:
- Git provides history
- Previous states are recoverable
- Rollback procedures documented

### 5. Least Privilege
Operations use minimum required permissions:
- User configs don't need sudo
- System changes require explicit elevation
- Service management isolated in containers

## Small-Scale Optimizations

### What We Don't Need
- Service mesh complexity
- Multi-region considerations  
- Auto-scaling policies
- Complex orchestration

### What We Emphasize
- Direct SSH access
- Manual approval gates
- Simple validation scripts
- Clear documentation

### Scale-Appropriate Tools
| Need | Enterprise | Small-Scale |
|------|------------|-------------|
| User Config | LDAP/AD | Chezmoi |
| System Config | Puppet/Chef | Ansible |
| Services | Kubernetes | Docker Compose |
| Secrets | Vault | .env files + templates |
| Monitoring | Prometheus | Simple health checks |

## Decision Framework

### When to Template
- Configuration varies by node → Template
- Configuration needs secrets → Template
- Configuration might change → Template
- Configuration is static → Direct file

### When to Automate
- Repeatable process → Script
- Complex validation → Script
- Error-prone manual steps → Script
- One-time setup → Document

### When to Centralize
- Identical across all nodes → Central management
- Node-specific requirements → Local management
- Mixed requirements → Template with variables

## Anti-Patterns to Avoid

### ❌ Manual Configuration
- SSH + vim to edit configs
- Undocumented changes
- "Quick fixes" outside version control

### ❌ Tool Overlap
- Multiple tools managing same files
- Unclear ownership boundaries
- Configuration conflicts

### ❌ Missing Validation
- Direct application without testing
- No dry-run capability
- Unclear what will change

### ❌ Implicit State
- Hidden dependencies
- Undocumented prerequisites
- Order-dependent operations

### ❌ All-or-Nothing Deployment
- Massive change sets
- No incremental rollout
- Cannot partially revert

## Success Metrics

### Configuration Quality
- ✓ All configuration in version control
- ✓ All changes validated before apply
- ✓ All operations idempotent
- ✓ All state explicit and discoverable

### Operational Excellence
- ✓ New node setup < 30 minutes
- ✓ Configuration drift detected < 24 hours
- ✓ Rollback possible < 5 minutes
- ✓ Change validation < 1 minute

### Developer Experience
- ✓ Clear command patterns
- ✓ Predictable outcomes
- ✓ Comprehensive documentation
- ✓ Fast feedback loops

## Getting Started

1. **Understand Your Scope**
   - Inventory your infrastructure
   - Identify configuration boundaries
   - Map tools to domains

2. **Establish Templates**
   - Start with most-changed configs
   - Extract variables progressively
   - Document as you go

3. **Build Validation**
   - Syntax checking first
   - Add dry-run capability
   - Implement approval gates

4. **Deploy Incrementally**
   - Start with single node
   - Validate thoroughly
   - Expand gradually

5. **Maintain Discipline**
   - Never bypass validation
   - Always use version control
   - Document exceptions

## Conclusion

This methodology provides professional-grade infrastructure management practices scaled appropriately for small clusters. It emphasizes safety, clarity, and maintainability while avoiding unnecessary complexity.

Remember: **Simple systems, professional practices.**
