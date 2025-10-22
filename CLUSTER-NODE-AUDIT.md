# Cluster Node Configuration Audit
**Date:** 2025-10-22
**Auditor:** Claude Code (automated)
**Purpose:** Assess conformity to cooperator baseline configuration

---

## Executive Summary

**Conformity Status:**
- ✅ All nodes have Debian 13 (Trixie)
- ✅ All nodes have chezmoi installed and configured
- ✅ All nodes have modern CLI tools (eza, bat, zoxide, starship, atuin)
- ✅ All nodes have Docker running
- ⚠️  **PRTR and DRTR are 3 commits behind on dotfiles** (need update)

---

## Node Comparison Matrix

| Aspect | CRTR (cooperator) | PRTR (projector) | DRTR (director) |
|--------|-------------------|------------------|-----------------|
| **Hardware** | RPi 5 (ARM64) | x86_64 PC | x86_64 PC |
| **RAM** | 16GB | 125GB | 62GB |
| **OS** | Debian 13 | Debian 13 | Debian 13 |
| **Kernel** | 6.12.47+rpt | 6.12.48+deb13 | 6.12.48+deb13 |
| **Chezmoi Version** | v2.66.0 | v2.64.0 | v2.65.1 |
| **Chezmoi Location** | ~/.local/bin | /usr/local/bin | ~/.local/bin |
| **Dotfiles Commit** | 582d066 (latest) | 68babbb (3 behind) | 68babbb (3 behind) |
| **Managed Files** | 13 files | 14 files | 14 files |
| **Modern Tools** | ✓ All | ✓ All | ✓ All |
| **Docker** | v28.5.1 | ✓ Running | ✓ Running |

---

## Detailed Node Configurations

### cooperator (crtr) - 192.168.254.10
**Role:** Edge services & cluster ingress node
**Architecture:** ARM64 (Raspberry Pi 5)
**Status:** ✅ **Baseline/Reference Configuration**

**Services Running:**
- Docker (v28.5.1)
- Caddy (reverse proxy)
- Cockpit (system management)
- Infisical (secrets management)

**Chezmoi Status:**
- Version: v2.66.0
- Location: ~/.local/bin/chezmoi
- Source: ~/.local/share/chezmoi
- Remote: git@github.com:IMUR/dotfiles.git
- Latest commit: `582d066 Remove cluster management scripts from dotfiles`
- Managed files: 13

**Dotfiles Managed:**
```
.bashrc
.config/atuin/config.toml
.config/starship.toml
.profile
.ssh/config
.ssh/rc
.tmux.conf
.zshrc
README.md
```

**Modern Tools:**
- ✅ eza (ls replacement)
- ✅ bat (cat replacement)
- ✅ zoxide (cd replacement)
- ✅ starship (prompt)
- ✅ atuin (shell history)
- ✅ docker (containers)

**Recent Changes:**
- Removed: `.cluster-functions.sh` (293 lines)
- Removed: `.cluster-mgmt.sh` (469 lines)
- Improved: `.ssh/rc` (simplified)
- Added: Infisical CLI v0.38.0
- Added: bind9-dnsutils (dig, nslookup)

---

### projector (prtr) - 192.168.254.20
**Role:** GPU/compute node
**Architecture:** x86_64
**Status:** ⚠️ **Needs dotfiles update**

**Services Running:**
- Docker
- (Various GPU/compute services on high ports: 3737, 8051, 8080, 54321)

**Chezmoi Status:**
- Version: v2.64.0 (2 minor versions behind)
- Location: /usr/local/bin/chezmoi (different from crtr!)
- Source: ~/.local/share/chezmoi
- Remote: git@github.com:IMUR/dotfiles.git
- Latest commit: `68babbb feat: use SSH environment file for PATH`
- **Behind by 3 commits**
- Managed files: 14

**Extra Files (outdated):**
```
.cluster-functions.sh  # Should be removed (293 lines)
.cluster-mgmt.sh       # Should be removed (469 lines)
```

**Modern Tools:**
- ✅ All tools installed and working

**Action Required:**
```bash
# On projector node
cd ~/.local/share/chezmoi
git pull origin main
chezmoi apply
```

---

### director (drtr) - 192.168.254.30
**Role:** Available/utility node
**Architecture:** x86_64
**Status:** ⚠️ **Needs dotfiles update**

**Services Running:**
- Docker

**Chezmoi Status:**
- Version: v2.65.1 (1 minor version behind)
- Location: ~/.local/bin/chezmoi (matches crtr)
- Source: ~/.local/share/chezmoi
- Remote: git@github.com:IMUR/dotfiles.git
- Latest commit: `68babbb feat: use SSH environment file for PATH`
- **Behind by 3 commits**
- Managed files: 14

**Extra Files (outdated):**
```
.cluster-functions.sh  # Should be removed (293 lines)
.cluster-mgmt.sh       # Should be removed (469 lines)
```

**Modern Tools:**
- ✅ All tools installed and working

**Action Required:**
```bash
# On director node
cd ~/.local/share/chezmoi
git pull origin main
chezmoi apply
```

---

## Conformity Gaps

### High Priority

1. **Outdated Dotfiles on PRTR & DRTR**
   - Impact: Missing recent improvements and removed obsolete scripts
   - Missing commits:
     1. `582d066` - Remove cluster management scripts
     2. `646732b` - Update SSH config for GitHub auth
     3. `34f7a82` - Add explicit GitHub SSH configuration
   - Fix: `git pull && chezmoi apply` on each node

2. **Chezmoi Installation Location Inconsistency**
   - CRTR & DRTR: `~/.local/bin/chezmoi` (user-local)
   - PRTR: `/usr/local/bin/chezmoi` (system-wide)
   - Impact: Minor - both work, but inconsistent
   - Recommendation: Standardize on `~/.local/bin` for user-managed tools

3. **Chezmoi Version Drift**
   - CRTR: v2.66.0 (latest)
   - PRTR: v2.64.0 (2 versions behind)
   - DRTR: v2.65.1 (1 version behind)
   - Impact: Low - all versions recent and compatible
   - Recommendation: Document update strategy

### Medium Priority

4. **Infisical CLI Not Installed on PRTR & DRTR**
   - Only installed on CRTR
   - Impact: Secrets management not available on other nodes
   - Recommendation: Install via dotfiles script or document manual installation

5. **DNS Tools Not Installed on PRTR & DRTR**
   - bind9-dnsutils (dig, nslookup) only on CRTR
   - Impact: Low - useful for debugging
   - Recommendation: Add to standard tool installation list

### Low Priority

6. **Docker Version Documentation**
   - Only verified on CRTR (v28.5.1)
   - Recommendation: Check versions on PRTR & DRTR for consistency

---

## Recommendations

### Immediate Actions

1. **Update PRTR & DRTR dotfiles:**
   ```bash
   # Run on prtr
   ssh prtr 'cd ~/.local/share/chezmoi && git pull && chezmoi apply'

   # Run on drtr
   ssh drtr 'cd ~/.local/share/chezmoi && git pull && chezmoi apply'
   ```

2. **Verify cluster-mgmt scripts removed:**
   ```bash
   ssh prtr 'ls -la ~/.cluster-*.sh' # Should not exist
   ssh drtr 'ls -la ~/.cluster-*.sh' # Should not exist
   ```

### Long-term Strategy

1. **Tool Installation via Chezmoi:**
   - Create `run_once_install-tools.sh` scripts in dotfiles
   - Include: Infisical CLI, DNS utils, common debugging tools
   - Ensures all nodes have same tooling

2. **Infisical Token Distribution:**
   - Decision needed: Shared token vs per-node tokens
   - If shared: Add encrypted file to chezmoi
   - If per-node: Use templating with node-specific tokens

3. **Standardize Chezmoi Installation:**
   - Document: Use `~/.local/bin` for all nodes
   - Update PRTR to match (optional, low priority)

4. **Version Update Automation:**
   - Consider chezmoi `run_onchange` scripts for tool updates
   - Or document manual update schedule (monthly?)

5. **Configuration Drift Monitoring:**
   - Create audit script (this document's methodology)
   - Run periodically to detect drift
   - Consider storing in crtr-config repo

---

## Conformity Checklist

Use this checklist when adding new nodes or auditing existing ones:

- [ ] Debian 13 (Trixie) installed
- [ ] Chezmoi installed (preferably in `~/.local/bin`)
- [ ] Dotfiles cloned from github.com/IMUR/dotfiles
- [ ] `chezmoi init` and `chezmoi apply` completed
- [ ] Modern CLI tools installed (eza, bat, zoxide, starship, atuin)
- [ ] Docker installed and running
- [ ] Dotfiles are up-to-date with main branch
- [ ] Infisical CLI installed (if using secrets management)
- [ ] DNS tools installed (bind9-dnsutils)
- [ ] SSH passwordless access working
- [ ] Passwordless sudo configured (if needed)
- [ ] /etc/hosts has cluster node entries
- [ ] Node-specific services configured (per role)

---

## Next Steps

1. ✅ Audit complete - documented current state
2. ⏳ Update PRTR & DRTR dotfiles to match CRTR
3. ⏳ Decide on Infisical token distribution strategy
4. ⏳ Create tool installation scripts for chezmoi
5. ⏳ Document node roles and service assignments

---

**Last Updated:** 2025-10-22
**Next Audit:** After PRTR/DRTR dotfiles update
