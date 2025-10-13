# .stems/ - Small-Scale Cluster Management Methodology

## What Is This?

`.stems/` contains a formalized Infrastructure-as-Code (IaC) and GitOps methodology specifically designed for small-scale cluster configuration management. It adapts enterprise best practices to the realities of managing a 3-node personal cluster.

**Relationship to `.meta/`:**
- `.meta/` = Current operational meta-management (principles, standards, SSOT)
- `.stems/` = Formalized methodology and patterns (how to build and manage)
- They coexist and complement each other

## Contents

```
.stems/
├── README.md               # This file
├── METHODOLOGY.md          # Core IaC/GitOps methodology
├── PRINCIPLES.md           # First-order and derived principles
├── CLUSTER-PATTERNS.md     # Specific patterns for 3-node clusters
├── LIFECYCLE.md            # Configuration lifecycle management
└── templates/              # Bootstrap templates for new systems
    ├── repository/         # New repo structure template
    ├── node-config/        # Node configuration template
    └── service/            # Service deployment template
```

## Quick Navigation

### By Question

| "I want to..." | Go to |
|----------------|-------|
| Understand the overall approach | [METHODOLOGY.md](METHODOLOGY.md) |
| Learn the core principles | [PRINCIPLES.md](PRINCIPLES.md) |
| See specific implementation patterns | [CLUSTER-PATTERNS.md](CLUSTER-PATTERNS.md) |
| Understand the configuration lifecycle | [LIFECYCLE.md](LIFECYCLE.md) |
| Bootstrap a new system | [templates/](templates/) |

### By Role

#### New to the System?
1. Start with [PRINCIPLES.md](PRINCIPLES.md) - understand the philosophy
2. Read [METHODOLOGY.md](METHODOLOGY.md) - learn the approach
3. Review [CLUSTER-PATTERNS.md](CLUSTER-PATTERNS.md) - see concrete examples

#### Setting Up a New Node?
1. Use [templates/node-config/](templates/node-config/) as starting point
2. Follow patterns in [CLUSTER-PATTERNS.md](CLUSTER-PATTERNS.md)
3. Validate using [LIFECYCLE.md](LIFECYCLE.md) Stage 3

#### Deploying a Service?
1. Check [templates/service/](templates/service/) for structure
2. Follow deployment patterns in [CLUSTER-PATTERNS.md](CLUSTER-PATTERNS.md#service-placement-strategy)
3. Use lifecycle stages from [LIFECYCLE.md](LIFECYCLE.md)

## Core Concepts

### The Methodology Stack

```
┌─────────────────────────────┐
│     User Experience         │ ← Unified across nodes
├─────────────────────────────┤
│    Configuration Layer      │ ← Templates + Variables
├─────────────────────────────┤
│    Validation Layer         │ ← Multi-stage checks
├─────────────────────────────┤
│     Tool Layer              │ ← Chezmoi, Ansible, Docker
├─────────────────────────────┤
│   Infrastructure Layer      │ ← 3 physical nodes
└─────────────────────────────┘
```

### Key Differentiators

This methodology is **not** another Kubernetes or enterprise framework. It's specifically designed for:

| Enterprise Approach | Our Approach |
|---------------------|--------------|
| Auto-scaling | Fixed 3-node topology |
| Service mesh | Direct SSH access |
| CI/CD pipelines | Manual approval gates |
| Centralized orchestration | Distributed management |
| Abstract everything | Explicit configuration |
| Automate everything | Automate the repetitive |

### Core Tools

The methodology assumes these tools but isn't dependent on them:

- **Chezmoi** - User configuration management (replaceable with any template system)
- **Ansible** - System configuration (replaceable with any configuration management)
- **Docker** - Service containerization (replaceable with systemd or other)
- **Git** - Version control (fundamental, not replaceable)

## How to Use This

### For Learning

Read in this order:
1. **PRINCIPLES.md** - Why we do things this way
2. **METHODOLOGY.md** - What we do
3. **CLUSTER-PATTERNS.md** - How we do it
4. **LIFECYCLE.md** - When we do it

### For Implementation

1. **Assess Current State**
   ```bash
   # What exists?
   ls -la ~/colab-config/
   
   # What's configured?
   chezmoi managed
   ansible-inventory --list
   docker ps
   ```

2. **Identify Gaps**
   - Missing validation?
   - No templates?
   - Manual processes?
   - Undocumented changes?

3. **Apply Methodology**
   - Start with one component
   - Add validation first
   - Create templates next
   - Document as you go

4. **Iterate**
   - Don't try to fix everything at once
   - Apply patterns incrementally
   - Learn from each iteration

### For New Projects

Use the templates to bootstrap:

```bash
# For a new repository
cp -r .stems/templates/repository/ ~/new-project/

# For a new node
cp -r .stems/templates/node-config/ ~/node-setup/

# For a new service
cp -r .stems/templates/service/ ~/services/new-service/
```

## Principles in Practice

### Example: Adding a New Service

Following the methodology:

1. **Planning** (LIFECYCLE Stage 1)
   - Define service requirements
   - Choose deployment node (CLUSTER-PATTERNS)
   - Document decision

2. **Development** (LIFECYCLE Stage 2)
   ```yaml
   # docker-compose.yml (following METHODOLOGY)
   version: '3.8'
   services:
     app:
       image: myapp:latest
       environment:
         NODE_NAME: ${HOSTNAME}  # Template variable
   ```

3. **Validation** (LIFECYCLE Stage 3)
   ```bash
   # Following PRINCIPLES of explicit validation
   docker compose config  # Syntax
   docker compose up --dry-run  # Simulation
   ```

4. **Deployment** (LIFECYCLE Stage 4)
   ```bash
   # Following CLUSTER-PATTERNS rolling update
   ssh crtr "cd services && docker compose up -d"
   ```

5. **Operation** (LIFECYCLE Stage 5-6)
   - Monitor health
   - Maintain configuration
   - Document changes

## Relationship to Existing Structure

### How .stems/ Complements .meta/

```
.meta/                          .stems/
├── foundation/                 ├── METHODOLOGY.md
│   ├── principles/      ←───── complements ─────→ ├── PRINCIPLES.md
│   ├── standards/               │
│   └── templates/       ←───── patterns for ────→ ├── templates/
│                               │
├── ssot/                       ├── CLUSTER-PATTERNS.md
│   └── (infrastructure truth)  │   └── (how to implement)
│                               │
└── whitelists/                 └── LIFECYCLE.md
    └── (structure rules)           └── (process flow)
```

### Migration Path

You don't need to migrate. The methodologies can coexist:

1. **Keep .meta/** for your current operational needs
2. **Use .stems/** for methodology reference
3. **Gradually adopt patterns** that make sense
4. **Eventually merge** if/when appropriate

## FAQ

### Q: Is this replacing .meta/?
No. `.meta/` is your operational meta-management. `.stems/` is a methodology framework. They serve different purposes.

### Q: Do I need to follow everything in .stems/?
No. It's a reference. Adopt what makes sense for your situation.

### Q: Can I modify the methodology?
Yes! It's designed to evolve. Document your changes and reasons.

### Q: How does this relate to industry standards?
It adapts IaC, GitOps, and SRE practices specifically for small-scale infrastructure.

### Q: What if I'm using different tools?
The principles and patterns still apply. Just substitute your tools.

## Next Steps

1. **Review the methodology** - Understand the approach
2. **Identify quick wins** - What can improve immediately?
3. **Plan adoption** - What makes sense for your context?
4. **Start small** - Pick one pattern and implement it
5. **Iterate** - Learn and adjust as you go

## Contributing

This methodology evolves through use:

1. **Try the patterns** - See what works
2. **Document variations** - Note what you changed and why
3. **Share learnings** - Update the documentation
4. **Propose improvements** - Submit PRs with enhancements

## Summary

`.stems/` provides a **professional-grade methodology** scaled appropriately for **small cluster management**. It emphasizes:

- **Explicit** over implicit
- **Simple** over complex
- **Safe** over fast
- **Clear** over clever

Use it as a reference, adapt it to your needs, and contribute improvements back.

---

*"Simple systems, professional practices."*
