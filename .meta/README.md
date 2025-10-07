# .meta - The Metadata Layer

This directory contains the **metadata layer** for crtr-config - the AI-first, schema-driven infrastructure that makes cooperator perfect.

---

## Purpose

The `.meta/` directory provides:

1. **Schemas** - JSON schemas that validate all state files
2. **AI Context** - Complete operational knowledge for AI assistants
3. **Generation Templates** - Jinja2 templates for config generation
4. **Validation Rules** - Additional validation beyond schemas
5. **Architecture Documentation** - The "why" behind the design

---

## Directory Structure

```
.meta/
├── README.md                   # This file
├── ARCHITECTURE.md             # Complete architecture documentation
├── VISION.md                   # Vision and transformation summary
├── EXAMPLE-FLOW.md             # End-to-end example workflow
│
├── schemas/                    # JSON Schema validation
│   ├── service.schema.json     # Service definitions
│   ├── domain.schema.json      # Domain routing
│   ├── network.schema.json     # Network configuration
│   └── node.schema.json        # Node identity
│
├── ai/                         # AI operational context
│   ├── context.json            # Complete operational context
│   ├── knowledge.yml           # Troubleshooting knowledge base
│   └── workflows.yml           # Common operational workflows
│
├── generation/                 # Config generation templates
│   ├── caddyfile.j2            # Caddy config generator
│   ├── dns-overrides.j2        # Pi-hole DNS generator
│   ├── systemd-unit.j2         # Systemd unit generator
│   └── docker-compose.j2       # Docker compose generator
│
└── validation/                 # Validation tools
    ├── validate.sh             # Schema validation runner
    └── rules.yml               # Additional validation rules
```

---

## How It Works

### 1. State Definition (Human)

Humans edit `state/*.yml`:
- `state/services.yml` - What services run
- `state/domains.yml` - How domains route
- `state/network.yml` - Network configuration
- `state/node.yml` - Node identity

### 2. Schema Validation (Automatic)

State files validated against `.meta/schemas/*.json`:
```bash
./tests/test-state.sh
# Uses schemas to validate structure, types, constraints
```

### 3. Config Generation (Automatic)

Templates in `.meta/generation/` generate configs from state:
```bash
./scripts/generate/regenerate-all.sh
# state/domains.yml + caddyfile.j2 → config/caddy/Caddyfile
# state/domains.yml + dns-overrides.j2 → config/pihole/local-dns.conf
```

### 4. AI Assistance (Continuous)

AI assistants use `.meta/ai/`:
- `context.json` - Understand repo structure
- `knowledge.yml` - Troubleshoot issues
- `workflows.yml` - Execute common tasks

---

## Key Files

### ARCHITECTURE.md

**Purpose**: Complete technical architecture documentation

**Read this to understand**:
- Schema-first philosophy
- State → Generation → Deployment flow
- AI integration patterns
- Benefits and trade-offs

**Target audience**: Developers, AI assistants, future maintainers

### VISION.md

**Purpose**: Vision and transformation summary

**Read this to understand**:
- What problem we're solving
- Before vs after comparison
- The promise to users
- Migration path

**Target audience**: Decision makers, stakeholders

### EXAMPLE-FLOW.md

**Purpose**: Complete end-to-end workflow example

**Read this to understand**:
- Concrete example (adding n8n)
- Every step from state edit to deployment
- Error handling and troubleshooting
- AI-assisted problem solving

**Target audience**: Implementers, operators

### ai/context.json

**Purpose**: Complete operational context for AI

**Contains**:
- Repository structure
- Node identity and role
- Service patterns
- File locations and purposes
- Common operations

**Usage**: AI queries this to understand operations

### ai/knowledge.yml

**Purpose**: Troubleshooting knowledge base

**Contains**:
- Known issues with symptoms
- Root causes and explanations
- Exact fixes (state changes + commands)
- Verification steps

**Usage**: AI queries by symptom to find solutions

### schemas/*.json

**Purpose**: JSON Schema validation for state files

**Contains**:
- Type definitions
- Required fields
- Constraints and patterns
- Relationships between entities

**Usage**: Automatic validation before deployment

---

## Workflows

### For Developers

1. **Read**: ARCHITECTURE.md → Understand the system
2. **Read**: EXAMPLE-FLOW.md → See it in action
3. **Build**: Implement generation templates
4. **Test**: Validate against schemas
5. **Deploy**: Use deployment automation

### For Operators

1. **Edit**: state/*.yml → Define desired state
2. **Validate**: ./tests/test-state.sh
3. **Generate**: ./scripts/generate/regenerate-all.sh
4. **Review**: Check generated configs
5. **Deploy**: ./deploy/deploy

### For AI Assistants

1. **Load**: .meta/ai/context.json → Understand system
2. **Query**: .meta/ai/knowledge.yml → Find solutions
3. **Validate**: .meta/schemas/*.json → Check state
4. **Suggest**: State changes, not direct config edits
5. **Verify**: Include verification steps

---

## Benefits

### Schema Validation

- ❌ **Before**: Edit YAML, hope it's correct, deploy, discover errors
- ✅ **After**: Edit YAML, automatic validation, errors before deployment

### Config Generation

- ❌ **Before**: Edit 3 files manually (Caddyfile, DNS, compose)
- ✅ **After**: Edit state once, 3 files generated consistently

### AI Assistance

- ❌ **Before**: AI guesses based on prose documentation
- ✅ **After**: AI queries structured knowledge, gives exact fixes

### Knowledge Capture

- ❌ **Before**: Troubleshooting knowledge scattered in commits, notes
- ✅ **After**: All knowledge in queryable .meta/ai/knowledge.yml

### Documentation

- ❌ **Before**: Manually update docs, easy to drift from reality
- ✅ **After**: Auto-generate docs from state, always in sync

---

## Implementation Status

### ✅ Completed

- [x] Architecture design (ARCHITECTURE.md)
- [x] Vision documentation (VISION.md)
- [x] Example workflow (EXAMPLE-FLOW.md)
- [x] Schema definitions (schemas/*.json)
- [x] AI context (ai/context.json)
- [x] Knowledge base (ai/knowledge.yml)

### 🚧 In Progress

- [ ] Generation templates (generation/*.j2)
- [ ] Validation tooling (validation/validate.sh)
- [ ] State migration (current docs → state/*.yml)
- [ ] Deployment automation (deploy/*)

### 📋 Planned

- [ ] Comprehensive testing
- [ ] CI/CD integration
- [ ] Live system sync (export/import)
- [ ] Complete documentation generation

---

## Getting Started

### For First-Time Readers

1. Start with **VISION.md** - Understand the "why"
2. Read **ARCHITECTURE.md** - Understand the "how"
3. Review **EXAMPLE-FLOW.md** - See it in action
4. Explore **ai/knowledge.yml** - See captured knowledge

### For Implementers

1. Study **schemas/*.json** - Understand state structure
2. Review **ai/context.json** - Understand operations
3. Build generation templates
4. Create deployment automation
5. Test and validate

### For AI Assistants

1. Load **ai/context.json** on startup
2. Query **ai/knowledge.yml** for troubleshooting
3. Validate suggestions against **schemas/*.json**
4. Always suggest state changes, never direct config edits

---

## Principles

### 1. State is Truth

The `state/*.yml` files are the **single source of truth**.
Everything else is derived from state.

### 2. Schemas Validate

All state must pass JSON schema validation.
Invalid state cannot be deployed.

### 3. Configs are Generated

Configuration files are **generated** from state.
Manual edits are **regenerated away**.

### 4. AI is First-Class

AI assistants have complete operational context.
Troubleshooting knowledge is structured and queryable.

### 5. Deployment is Idempotent

Running deployment repeatedly is safe.
System converges to desired state.

---

## Meta

**Version**: 1.0.0
**Created**: 2025-10-07
**Purpose**: Schema-first, AI-assisted infrastructure for cooperator
**Philosophy**: State drives everything. Schemas validate. AI assists. Configs generate.

This is the metadata layer that makes cooperator perfect.
