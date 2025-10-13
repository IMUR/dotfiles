# Implementation Roadmap

Path from current crtr-config to schema-first perfection.

---

## Current State Assessment

### What We Have
- ✅ COOPERATOR-ASPECTS.md (complete technical reference)
- ✅ Infrastructure scripts (ssot/, dns/)
- ✅ Service documentation (scattered)
- ✅ Working configurations (on live system)
- ✅ Hard-won troubleshooting knowledge (in git history/memory)

### What We Don't Have
- ❌ Schema validation
- ❌ State-driven configuration
- ❌ Automated deployment
- ❌ Structured troubleshooting knowledge
- ❌ Config generation from state

---

## Implementation Phases

### Phase 1: Foundation (Week 1)

**Goal**: Establish schema-first structure

**Tasks**:
1. Complete JSON schemas
   - [x] service.schema.json (basic version created)
   - [x] domain.schema.json (basic version created)
   - [ ] network.schema.json
   - [ ] node.schema.json

2. Migrate knowledge to structured format
   - [x] .meta/ai/knowledge.yml (created with examples)
   - [ ] Add all known issues from git history
   - [ ] Add all service-specific quirks
   - [ ] Add all deployment gotchas

3. Create validation tooling
   - [ ] .meta/validation/validate.sh
   - [ ] Schema validation runner
   - [ ] State cross-reference checker

**Deliverable**: Can validate state files against schemas

**Time**: 2-3 days

---

### Phase 2: State Migration (Week 1-2)

**Goal**: Current configuration → state/*.yml

**Tasks**:
1. Create state/node.yml
   - Source: COOPERATOR-ASPECTS.md → BASE SYSTEM section
   - Hostname, IP, timezone, packages, etc.

2. Create state/services.yml
   - Source: COOPERATOR-ASPECTS.md → SERVICES section
   - All systemd services
   - All Docker containers
   - Port bindings, data paths, etc.

3. Create state/domains.yml
   - Source: COOPERATOR-ASPECTS.md → GATEWAY section
   - All domain routes
   - Reverse proxy types
   - Local DNS overrides

4. Create state/network.yml
   - Source: COOPERATOR-ASPECTS.md → NETWORK section
   - Interfaces, DNS, NFS exports
   - DuckDNS configuration

5. Validate all state files
   - Run against schemas
   - Fix validation errors
   - Ensure cross-references are valid

**Deliverable**: Complete, valid state/*.yml files

**Time**: 3-4 days

**Validation**:
```bash
./meta/validation/validate.sh
# All state files pass schema validation
# Cross-references verified (services ↔ domains)
```

---

### Phase 3: Config Generation (Week 2)

**Goal**: state/*.yml → config/*

**Tasks**:
1. Create generation templates
   - [ ] .meta/generation/caddyfile.j2
   - [ ] .meta/generation/dns-overrides.j2
   - [ ] .meta/generation/systemd-unit.j2
   - [ ] .meta/generation/docker-compose.j2

2. Build generation script
   - [ ] scripts/generate/regenerate-all.sh
   - Reads state/*.yml
   - Applies templates
   - Writes to config/*
   - Marks as generated

3. Test generation
   - Generate all configs from state
   - Compare to live system configs
   - Verify equivalence
   - Fix discrepancies

**Deliverable**: Can generate all configs from state

**Time**: 4-5 days

**Validation**:
```bash
./scripts/generate/regenerate-all.sh
diff -r config/ /etc/caddy/Caddyfile
diff -r config/ /etc/dnsmasq.d/
# Generated configs match live system
```

---

### Phase 4: Deployment Automation (Week 3)

**Goal**: Executable deployment system

**Tasks**:
1. Create deployment library
   - [ ] deploy/lib/deploy-lib.sh
   - [ ] deploy/lib/state-query.sh
   - [ ] deploy/lib/config-gen.sh
   - Common functions for phases

2. Build deployment phases
   - [ ] deploy/phases/01-base.sh (packages, system)
   - [ ] deploy/phases/02-storage.sh (NFS, /cluster-nas)
   - [ ] deploy/phases/03-network.sh (DNS, DuckDNS)
   - [ ] deploy/phases/04-services.sh (systemd, docker)
   - [ ] deploy/phases/05-gateway.sh (Caddy, routing)
   - [ ] deploy/phases/06-verify.sh (comprehensive tests)

3. Create main deployment CLI
   - [ ] deploy/deploy (main entry point)
   - Parse arguments (all, phase, service)
   - Execute phases in order
   - Handle errors gracefully

4. Build verification scripts
   - [ ] deploy/verify/verify-base.sh
   - [ ] deploy/verify/verify-network.sh
   - [ ] deploy/verify/verify-services.sh
   - [ ] deploy/verify/verify-all.sh

**Deliverable**: ./deploy/deploy all works

**Time**: 5-7 days

**Validation**:
Test on fresh Raspberry Pi OS in VM or container:
```bash
./deploy/deploy all
# 20-30 minutes later: fully operational system
./deploy/verify/verify-all.sh
# All checks pass
```

---

### Phase 5: Documentation Generation (Week 3-4)

**Goal**: state/*.yml → docs/*.md

**Tasks**:
1. Create documentation templates
   - [ ] .meta/generation/deploy-doc.j2
   - [ ] .meta/generation/reference-doc.j2
   - [ ] .meta/generation/services-doc.j2

2. Build doc generator
   - [ ] scripts/generate/regenerate-docs.sh
   - Generate from state + templates
   - Include in regenerate-all.sh

3. Generate all documentation
   - [ ] docs/DEPLOY.md (from state + phases)
   - [ ] docs/REFERENCE.md (from state)
   - [ ] docs/SERVICES.md (from state/services.yml)
   - [ ] docs/TROUBLESHOOTING.md (from .meta/ai/knowledge.yml)

**Deliverable**: Auto-generated, always-current documentation

**Time**: 2-3 days

---

### Phase 6: Testing & Validation (Week 4)

**Goal**: Comprehensive test suite

**Tasks**:
1. Create test framework
   - [ ] tests/test-state.sh (schema validation)
   - [ ] tests/test-generation.sh (config generation)
   - [ ] tests/test-deployment.sh (deployment in container)

2. Test scenarios
   - [ ] Fresh install deployment
   - [ ] Service addition
   - [ ] Service modification
   - [ ] State export/import
   - [ ] Disaster recovery

3. CI/CD integration
   - [ ] GitHub Actions workflow
   - [ ] Automatic validation on commit
   - [ ] Test deployment in container

**Deliverable**: Automated testing prevents regressions

**Time**: 3-4 days

---

### Phase 7: Migration & Cutover (Week 4)

**Goal**: Replace old structure with new

**Tasks**:
1. Sync utilities
   - [ ] scripts/sync/export-state.sh (system → state)
   - [ ] scripts/sync/import-state.sh (state → system)

2. Final validation
   - Deploy from state to test system
   - Verify against live cooperator
   - Fix any discrepancies

3. Cutover
   - [ ] Update CLAUDE.md to reference new structure
   - [ ] Update README.md
   - [ ] Delete old documentation
     - ❌ Remove ASPECTS.md
     - ❌ Remove BUILD-PLAN.md
     - ❌ Remove old state/ directory
     - ❌ Remove incomplete aspects/ directory
   - [ ] Git commit "Schema-first migration complete"

**Deliverable**: Clean, schema-first repository

**Time**: 2 days

---

## Timeline Summary

**Total Time**: 3-4 weeks

**Week 1**:
- Phase 1: Foundation (2-3 days)
- Phase 2: State Migration (3-4 days)

**Week 2**:
- Phase 2: State Migration complete
- Phase 3: Config Generation (4-5 days)

**Week 3**:
- Phase 4: Deployment Automation (5-7 days)

**Week 4**:
- Phase 5: Documentation Generation (2-3 days)
- Phase 6: Testing & Validation (3-4 days)
- Phase 7: Migration & Cutover (2 days)

---

## Milestones

### M1: Schema Foundation (End of Week 1)
- ✅ Complete schemas
- ✅ Complete state files
- ✅ Can validate state

### M2: Generation Working (End of Week 2)
- ✅ Config generation from state
- ✅ Generated configs match live system
- ✅ Documentation generation working

### M3: Deployment Working (End of Week 3)
- ✅ Can deploy from state
- ✅ Can verify deployment
- ✅ Deployment is idempotent

### M4: Complete System (End of Week 4)
- ✅ Full test suite passing
- ✅ CI/CD operational
- ✅ Old structure removed
- ✅ Schema-first is production

---

## Risk Mitigation

### Risk: Generated configs don't match live system

**Mitigation**:
- Test generation early
- Compare diffs carefully
- Keep live system as reference
- Can always fall back to manual

### Risk: Deployment breaks live system

**Mitigation**:
- Test in VM/container first
- Have microSD backup (already created)
- Can boot from USB backup
- Incremental deployment (phase by phase)

### Risk: State model doesn't capture everything

**Mitigation**:
- Start with current COOPERATOR-ASPECTS.md
- Add to schemas as needed
- Extensible design allows additions
- Can always add more fields

### Risk: Takes longer than planned

**Mitigation**:
- Phases are independent
- Can pause after any phase
- Each phase delivers value
- Not a big-bang migration

---

## Success Criteria

### After Phase 2 (State Migration)
```bash
./meta/validation/validate.sh
# Returns: All state files valid ✓
```

### After Phase 3 (Config Generation)
```bash
./scripts/generate/regenerate-all.sh
diff config/caddy/Caddyfile /etc/caddy/Caddyfile
# Returns: No differences (or documented acceptable diffs)
```

### After Phase 4 (Deployment)
```bash
# Fresh Raspberry Pi OS in VM
./deploy/deploy all
# Returns: Deployment complete ✓
curl -I https://n8n.ism.la
# Returns: 200 OK
```

### After Phase 7 (Complete)
```bash
# Fresh Raspberry Pi OS on USB drive
git clone /cluster-nas/repos/crtr-config.git
cd crtr-config
./deploy/deploy all
# 20 minutes later: fully operational cooperator
./deploy/verify/verify-all.sh
# Returns: All verifications passed ✓
```

---

## Quick Start (After Implementation)

### For Fresh Install
```bash
# 1. Flash Raspberry Pi OS Lite to USB
# 2. Boot with /cluster-nas drive connected
# 3. Clone repository
git clone /cluster-nas/repos/crtr-config.git ~/crtr-config
cd ~/crtr-config

# 4. Deploy
./deploy/deploy all

# 5. Verify
./deploy/verify/verify-all.sh

# Done. Fully operational cooperator.
```

### For Modifications
```bash
# 1. Edit state
vim state/services.yml  # Add new service

# 2. Validate
./tests/test-state.sh

# 3. Generate
./scripts/generate/regenerate-all.sh

# 4. Review
cat config/caddy/Caddyfile  # Check generated config

# 5. Deploy
./deploy/deploy service newservice

# 6. Verify
./deploy/verify/verify-newservice.sh

# Done. New service operational.
```

---

## Next Steps

**Immediate** (This Week):
1. Review this roadmap
2. Approve approach
3. Begin Phase 1 (Foundation)

**Phase 1 Start**:
1. Complete network.schema.json
2. Complete node.schema.json
3. Create .meta/validation/validate.sh
4. Test schema validation

**Ready to begin implementation?**

This is the path to perfection.
