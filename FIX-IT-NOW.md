# Fix It Now - Executable Action Plan

**Problem**: Documentation describes systems that don't exist
**Solution**: Make documentation honest, then proceed with migration

---

## Step 1: Security (15 minutes) - BLOCKER

Follow `SECURITY-QUICK-FIX.md` exactly:
1. Generate new DuckDNS token at https://www.duckdns.org
2. Store in `/etc/crtr-config/secrets/duckdns.token` (chmod 600)
3. Update `state/network.yml` to use `token_file` reference
4. Remove `backups/dns/duckdns/duckdns.md` from git
5. Test new token works

**Until this is done, DO NOT MIGRATE**

---

## Step 2: Documentation Honesty (1-2 hours)

### 2A: Create IMPLEMENTATION-STATUS.md (10 minutes)

```bash
cat > IMPLEMENTATION-STATUS.md << 'EOF'
# Implementation Status

## TL;DR: State Files + Manual Deployment

This repository is in **Phase 1**: State-driven configuration with manual deployment.

### What Actually Works

✅ **State Files** (`state/*.yml`)
- 4 YAML files define desired system state
- Valid, well-structured, maintainable
- Use as reference specifications

✅ **Config Files** (`config/`)
- Caddy, Pi-hole, systemd, docker configs
- Maintained manually (not generated)
- Deployable to system

✅ **Validation** (`.meta/validation/validate.sh`)
- YAML syntax checking only
- No structural validation (no JSON schemas)

✅ **Backups** (`backups/`)
- Known-good configs archived
- Use for migration deployment

### What Doesn't Exist (Yet)

❌ **Generation Templates** (`.meta/generation/*.j2`)
- Documentation references Jinja2 templates
- Directory doesn't exist
- `scripts/generate/regenerate-all.sh` will fail

❌ **JSON Schemas** (`.meta/schemas/*.json`)
- Documented in architecture docs
- Directory doesn't exist
- No structural validation available

❌ **AI Context** (`.meta/ai/*.json`)
- Referenced in CLAUDE.md
- Directory doesn't exist
- Not needed for operations

❌ **Deploy Automation** (`deploy/`)
- Referenced in migration docs
- Directory doesn't exist
- Use manual deployment

### Migration Workflow (Actual)

**Don't use documented workflow - it references non-existent tools**

**Use this instead**:

```bash
# 1. Validate state (syntax only)
./.meta/validation/validate.sh

# 2. Use state as reference, deploy from config/ or backups/
sudo cp config/caddy/Caddyfile /etc/caddy/
sudo cp config/pihole/local-dns.conf /etc/dnsmasq.d/02-custom-local-dns.conf
# etc...

# 3. Verify manually
systemctl status caddy
dig @localhost test.ism.la
curl -I https://n8n.ism.la

# 4. Rollback if needed (boot order change)
```

### Future: Implement Generation Pipeline

**When time permits**:
1. Create Jinja2 templates in `.meta/generation/`
2. Test `scripts/generate/regenerate-all.sh`
3. Create JSON schemas for validation
4. Enable full state → generate → deploy workflow

**Until then**: State files are reference specs, configs are manually maintained

---

**Last Updated**: 2025-10-13
EOF
```

### 2B: Fix README.md (15 minutes)

```bash
# Back up current README
cp README.md README.md.backup

# Edit README.md
vim README.md
```

**Changes**:

```markdown
## Essential Commands

### State Validation
```bash
# Validate state file syntax
./.meta/validation/validate.sh
```

### Configuration
```bash
# Config files are in config/ directory
# Deploy manually to system:
sudo cp config/caddy/Caddyfile /etc/caddy/
sudo systemctl reload caddy
```

### Migration
```bash
# See docs/MIGRATION-PROCEDURE.md for manual deployment workflow
```

**Note**: Generation pipeline (Jinja2 templates) planned but not yet implemented.
See IMPLEMENTATION-STATUS.md for current capabilities.
```

### 2C: Fix CLAUDE.md (15 minutes)

```bash
# Back up
cp CLAUDE.md CLAUDE.md.backup

# Edit
vim CLAUDE.md
```

**Find this section**:
```markdown
**Required reading order**:
1. START-HERE.md
2. .meta/ai/context.json
3. .meta/ai/knowledge.yml
4. .meta/ARCHITECTURE.md
```

**Replace with**:
```markdown
**Required reading order**:
1. START-HERE.md - Overview
2. IMPLEMENTATION-STATUS.md - What actually exists
3. docs/architecture/ARCHITECTURE.md - Target architecture
4. docs/architecture/VISION.md - Why schema-first

**Note**: `.meta/ai/` directory planned but not implemented. Current system uses
state files as reference, manual config deployment.
```

**Find**:
```markdown
./tests/test-state.sh
./scripts/generate/regenerate-all.sh
./deploy/deploy <target>
```

**Replace with**:
```markdown
./.meta/validation/validate.sh         # YAML syntax validation only
# Config generation planned but not implemented
# Manual deployment (no deploy/ automation)
```

### 2D: Update docs/MIGRATION-PROCEDURE.md (30 minutes)

Add at the top:

```markdown
# Migration Procedure (Manual Deployment)

**⚠️ IMPORTANT**: This migration uses **manual deployment**, not automated generation.

See `IMPLEMENTATION-STATUS.md` for why. TL;DR: Jinja2 templates and deploy/
automation are planned but not yet implemented.

## Approach

**State files** (`state/*.yml`) = specification reference
**Config files** (`config/` or `backups/`) = actual deployable files
**Deployment** = manual copy + verify

---
```

Then update Step 3 (deployment):

**Old**:
```bash
./scripts/generate/regenerate-all.sh
git diff config/
./deploy/deploy all
```

**New**:
```bash
# Use state/*.yml as reference specification
# Deploy from config/ directory (manually maintained)

# Caddy
sudo cp config/caddy/Caddyfile /etc/caddy/
sudo systemctl reload caddy

# Pi-hole DNS
sudo cp config/pihole/local-dns.conf /etc/dnsmasq.d/02-custom-local-dns.conf
sudo systemctl restart pihole-FTL

# Systemd services
for service in atuin-server gotty semaphore; do
    sudo cp config/systemd/${service}.service /etc/systemd/system/
done
sudo systemctl daemon-reload

# Docker Compose services
cd /cluster-nas/services/n8n
docker compose up -d
```

### 2E: Move review artifacts (5 minutes)

```bash
mkdir -p archives/review-artifacts-2025-10-13

git mv HANDOFF-2025-10-13-CLEANUP.md archives/review-artifacts-2025-10-13/
git mv DOCUMENTATION-QUALITY-ASSESSMENT.md archives/review-artifacts-2025-10-13/

# Keep security docs for now (will move after token rotation)
```

---

## Step 3: Commit Changes (5 minutes)

```bash
git add -A
git commit -m "docs: fix documentation-reality mismatch

- Add IMPLEMENTATION-STATUS.md (actual capabilities)
- Fix README.md (remove non-existent commands)
- Fix CLAUDE.md (remove non-existent AI files)
- Update MIGRATION-PROCEDURE.md (manual deployment)
- Archive review artifacts

Documentation now accurately reflects Phase 1 implementation:
- State files as reference specs
- Manual config maintenance
- No generation pipeline (planned, not implemented)

Migration can proceed safely with manual deployment approach.
"

git push
```

---

## Step 4: Test Migration Readiness (30 minutes)

```bash
# Validate state files
./.meta/validation/validate.sh

# Verify configs are deployable
ls -lh config/caddy/Caddyfile
ls -lh config/pihole/local-dns.conf
ls -lh config/systemd/*.service

# Check backups available
ls -lh backups/

# Verify USB prepared
lsblk | grep sdb

# Verify NAS mount
df -h /cluster-nas
```

**If all checks pass**: Ready for migration

---

## Timeline

| Step | Time | Status |
|------|------|--------|
| 1. Security (token rotation) | 15 min | 🔴 BLOCKER |
| 2A. IMPLEMENTATION-STATUS.md | 10 min | ⏳ |
| 2B. Fix README.md | 15 min | ⏳ |
| 2C. Fix CLAUDE.md | 15 min | ⏳ |
| 2D. Update MIGRATION-PROCEDURE.md | 30 min | ⏳ |
| 2E. Move artifacts | 5 min | ⏳ |
| 3. Commit changes | 5 min | ⏳ |
| 4. Test migration readiness | 30 min | ⏳ |
| **TOTAL** | **2 hours** | |

---

## What This Accomplishes

✅ **Honest documentation** - Describes what exists, not what's planned
✅ **Clear migration path** - Manual deployment approach documented
✅ **Security fixed** - Token rotated, secrets managed properly
✅ **Artifacts archived** - Review docs out of active workspace
✅ **Migration ready** - Can proceed safely with manual approach

## What This Doesn't Do

- ❌ Doesn't implement Jinja2 templates (do after migration)
- ❌ Doesn't consolidate all docs (do after migration)
- ❌ Doesn't create JSON schemas (do after migration)
- ❌ Doesn't define all tool boundaries (do after migration)

**Philosophy**: Get documentation honest, migrate safely, enhance later

---

## After Migration (Post-Mortem)

**When system is stable (1 week+)**:

1. Consolidate docs (27 files → 15 files)
2. Decide: Implement templates OR accept manual configs
3. Create TOOL-BOUNDARIES.md (crtr-config vs dotfiles vs colab-config)
4. Consider: Create deploy/ automation (if desired)

**Don't rush these** - let the system prove stable first

---

**Next Action**: Execute Step 1 (Security fix) then Step 2 (Documentation fixes)
