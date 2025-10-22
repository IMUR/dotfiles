# Cluster Management Discussion
**Created:** 2025-10-21
**Purpose:** Document cluster management functionality previously in dotfiles scripts
**Status:** UNDER CONSIDERATION - Scripts removed, functionality to be redesigned

---

## Background

During the migration to fresh Debian 13, we discovered 3 scripts in the dotfiles repository that were managing cluster-wide operations. These were removed on 2025-10-21 because:

1. **Not explicitly requested** - Appeared in dotfiles without clear purpose documentation
2. **Not audited** - Security and quality review revealed potential issues
3. **Migration timing** - Fresh start is ideal time to reconsider architecture
4. **Complexity** - 750+ lines of bash managing critical cluster operations

**Previous scripts removed:**
- `dot_cluster-functions.sh` (293 lines) - Tmux cluster session management
- `dot_cluster-mgmt.sh` (469 lines) - Dotfile sync across cluster
- `dot_ssh/executable_rc` (14 lines) - SSH session PATH setup

---

## Cluster Infrastructure

### Current Node Status
- **cooperator (crtr)** - 192.168.254.10 - Gateway/coordinator - ✅ UP (migrating)
- **projector (prtr)** - 192.168.254.20 - GPU node - ❌ DOWN
- **director (drtr)** - 192.168.254.30 - GPU node - ✅ UP
- **terminator (trtr)** - 192.168.254.40 - Pseudo node - ✅ UP
- **zerouter (zrtr)** - 192.168.254.11 - Pseudo node - ❌ DOWN

**Core nodes:** crtr, prtr, drtr (primary cluster)
**Pseudo nodes:** trtr, zrtr (supporting infrastructure)

### Migration Plan
1. **Phase 1:** Complete crtr migration (current)
2. **Phase 2:** Migrate drtr and trtr (already up)
3. **Phase 3:** Address prtr and zrtr when brought online

---

## Topic 1: Tmux Multi-Node Session Management

### What It Did

**Previous script:** `dot_cluster-functions.sh`

Provided convenience functions for:
- Creating tmux sessions with multiple SSH panes (one per node)
- Synchronized input across all nodes
- Quick node navigation within tmux
- Cluster-wide tmux session listing
- Connectivity checking

**Key functions:**
```bash
tmux-cluster              # Create 3-pane layout: crtr, prtr, drtr
tmux-gpu                  # Create 2-pane layout: prtr, drtr (GPU nodes only)
tmux-sync-on/off          # Type once, execute on all panes
tn <node>                 # New tmux window, SSH to node
cluster-ping              # Check which nodes are reachable
cluster-tmux-list         # Show all tmux sessions on all nodes
```

### Discussion Points

**Pros:**
- Convenient for cluster-wide operations
- Common pattern for multi-server management
- tmux is already in stack
- Reduces repetitive SSH commands

**Cons:**
- 300 lines of bash for tmux convenience
- Could be replaced with:
  - Simple shell aliases
  - Tmux configuration only
  - External tools (ClusterShell, pssh, ansible)
  - Custom script outside dotfiles

**Questions to consider:**

1. **How often do we need multi-node tmux sessions?**
   - Daily operations?
   - Occasional debugging?
   - Cluster-wide updates?

2. **Is tmux the right tool for this?**
   - Alternatives: ClusterShell (clush), parallel-ssh, ansible ad-hoc
   - tmux is great for interactive work, but limiting for automation

3. **Should this be in dotfiles at all?**
   - dotfiles = personal shell environment
   - cluster management = separate concern
   - Could live in ~/bin/ or /usr/local/bin/ instead

4. **Do we need synchronized input?**
   - Dangerous if misused (rm -rf across all nodes)
   - Better alternatives: ansible, ClusterShell groups
   - Can be achieved with simple tmux config: `bind-key s setw synchronize-panes`

**Potential alternatives:**

### Option A: Minimal tmux.conf additions
```tmux
# In ~/.tmux.conf
bind-key C new-window -n cluster \; \
    split-window -h \; \
    split-window -v \; \
    send-keys -t 0 "ssh crtr" C-m \; \
    send-keys -t 1 "ssh prtr" C-m \; \
    send-keys -t 2 "ssh drtr" C-m

bind-key s setw synchronize-panes
```

### Option B: Dedicated cluster management tool
```bash
# ~/bin/cluster-session
#!/bin/bash
tmux new-session -d -s cluster -n all
tmux split-window -h -t cluster:all
tmux split-window -v -t cluster:all.1
tmux send-keys -t cluster:all.0 "ssh crtr" C-m
tmux send-keys -t cluster:all.1 "ssh prtr" C-m
tmux send-keys -t cluster:all.2 "ssh drtr" C-m
tmux attach-session -t cluster
```

### Option C: Use ClusterShell
```bash
# Install: apt install clustershell
# Configure /etc/clustershell/groups
# Use: clush -g all 'uptime'
```

### Option D: Use Ansible ad-hoc commands
```bash
# Already have ansible in migration plan
ansible all -m shell -a 'uptime'
ansible gpu -m shell -a 'nvidia-smi'
```

**Recommendation:** Defer decision until crtr migration complete, then evaluate based on actual usage patterns.

---

## Topic 2: Automated Dotfile Distribution

### What It Did

**Previous script:** `dot_cluster-mgmt.sh`

Provided cluster-wide dotfile synchronization:
- Auto-commit and push dotfile changes from any node
- Deploy to all nodes via SSH + chezmoi
- Interactive prompts and validation
- Dry-run mode for safety
- Git conflict detection

**Key functions:**
```bash
push-dotfiles -m "Update aliases"  # Commit, push, deploy to all nodes
sync-dotfiles                       # Pull and apply latest on current node
cluster-status                      # Check which nodes have chezmoi
```

### Discussion Points

**Pros:**
- Convenient for keeping cluster in sync
- Validates git state before deploying
- Interactive prompts prevent mistakes
- Dry-run mode for safety

**Cons:**
- 470 lines of complex bash
- Mixes concerns: git management + cluster deployment
- Auto-commit can create messy git history
- Assumes all nodes should have identical dotfiles (may not be true)

**Questions to consider:**

1. **Should all nodes have identical dotfiles?**
   - Current approach: Templates with node-aware variables
   - Maybe some nodes need different configs?
   - Example: GPU nodes might need CUDA paths, cooperator doesn't

2. **Is automation necessary?**
   - Chezmoi already handles dotfile templating
   - Git already handles version control
   - SSH already provides remote access
   - Why add another layer?

3. **What's the correct workflow?**
   - **Current removed approach:** Edit on any node → auto-commit → auto-deploy
   - **Manual approach:** Edit → test → commit → push → SSH + chezmoi update
   - **CI/CD approach:** Push to GitHub → webhook → nodes pull automatically
   - **Ansible approach:** Ansible playbook deploys dotfiles

4. **How to handle node-specific changes?**
   - Template variables (current chezmoi approach)
   - Separate branches per node?
   - Different dotfile repos per node type?

**Potential alternatives:**

### Option A: Simple manual workflow (recommended for now)
```bash
# On cooperator (or any node):
cd ~/.local/share/chezmoi
# Edit templates
chezmoi diff              # Preview changes
chezmoi apply             # Test locally
git add . && git commit -m "Update thing"
git push

# On other nodes:
ssh drtr
chezmoi update            # Pull from git + apply
```

### Option B: Ansible playbook
```yaml
# ~/ansible/dotfiles-sync.yml
- hosts: all
  tasks:
    - name: Update dotfiles via chezmoi
      command: chezmoi update
      become: yes
      become_user: crtr

# Run: ansible-playbook dotfiles-sync.yml
```

### Option C: Git hooks + systemd timer
```bash
# On each node:
# /etc/systemd/system/dotfiles-sync.timer
# Runs every hour, pulls latest dotfiles

[Unit]
Description=Sync dotfiles via chezmoi

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

### Option D: Webhook-based deployment
```
GitHub → webhook → cooperator → ansible → all nodes update
```

**Recommendation:**
- **Short-term:** Manual workflow (Option A) - simple, predictable, safe
- **Long-term:** Evaluate after migrating drtr/trtr, see if automation is needed
- **Future consideration:** Ansible playbook (Option B) if automation desired

---

## Topic 3: SSH Session Initialization

### What It Did

**Previous script:** `dot_ssh/executable_rc`

Ran on **every SSH session** to:
- Overwrite `~/.ssh/environment` with hardcoded PATH
- Source `~/.profile` (silently)

### Discussion Points

**Pros:**
- Ensures consistent PATH on SSH sessions
- Handles non-login shells

**Cons:**
- **Overwrites file on every login** - creates filesystem writes constantly
- Hardcoded paths with string substitution (fragile)
- Modern SSH + shell profiles handle this better
- Side effects hard to debug

**Questions to consider:**

1. **Is this solving a real problem?**
   - PATH is already correct (verified 2025-10-21)
   - Shell configs (.profile, .zshrc) already set PATH
   - This was likely a workaround for older config

2. **Why was it needed before?**
   - Possible: Old SSH config required PermitUserEnvironment
   - Possible: Non-login shells weren't sourcing .profile
   - Possible: Cargo/atuin bins weren't in PATH for SSH

3. **Is it needed now?**
   - **NO** - Current PATH is correct without it
   - Shell configs are templated by chezmoi
   - Modern SSH sources ~/.profile correctly

**Recommendation:** **DO NOT RESTORE** - shell configs handle PATH correctly

---

## Alternative Approaches to Cluster Management

### Philosophy: Separation of Concerns

**Dotfiles should contain:**
- Personal shell configuration (.zshrc, .bashrc, .profile)
- Editor configs (.vimrc, nvim/)
- Tool configs (starship, tmux, git)
- SSH config (connections, keys)

**Dotfiles should NOT contain:**
- Cluster orchestration logic
- Multi-node deployment systems
- Complex bash automation

**Better homes for cluster management:**

### 1. SSOT Tools (Already in crtr-config)
```
crtr-config/
├── ssot/               # Single source of truth
│   ├── nodes.yaml      # Node definitions
│   ├── services.yaml   # Service configurations
│   └── ...
└── tools/              # Tools that operate on SSOT
    ├── validate.sh
    └── deploy.sh       # Could include cluster deployment
```

**Advantages:**
- Declarative configuration
- Version controlled in project repo
- Separate from personal dotfiles
- Can be used by automation tools

### 2. Ansible (Already in migration plan)
```
~/ansible/
├── inventory.yml       # Cluster node inventory
├── playbooks/
│   ├── dotfiles.yml    # Deploy chezmoi
│   ├── services.yml    # Deploy docker/caddy/etc
│   └── cluster.yml     # Full cluster setup
└── group_vars/
    ├── gpu.yml         # GPU node specific
    └── all.yml         # All nodes
```

**Advantages:**
- Industry standard
- Idempotent (safe to re-run)
- Rich module ecosystem
- Handles complex dependencies

### 3. Simple Scripts in ~/bin/
```bash
~/bin/cluster-tmux      # Tmux multi-node session
~/bin/cluster-sync      # Sync dotfiles to all nodes
~/bin/cluster-cmd       # Run command on all nodes
```

**Advantages:**
- Not in dotfiles (no cross-node pollution)
- Node-specific (cooperator might be only coordinator)
- Easy to test and modify
- Clear separation from personal configs

### 4. Makefile in crtr-config/
```makefile
# crtr-config/Makefile

.PHONY: sync-dotfiles deploy-services cluster-status

sync-dotfiles:
	@for node in crtr prtr drtr; do \
		ssh $$node 'chezmoi update'; \
	done

deploy-services:
	ansible-playbook ansible/services.yml

cluster-status:
	@for node in crtr prtr drtr trtr zrtr; do \
		echo -n "$$node: "; \
		ssh -o ConnectTimeout=2 $$node 'uptime' 2>/dev/null || echo "DOWN"; \
	done
```

**Advantages:**
- Standard tool (make)
- Self-documenting (`make help`)
- Easy to extend
- Lives with project, not dotfiles

---

## Decisions Needed

### Before migrating drtr and trtr:

1. **Multi-node tmux sessions:**
   - [ ] Do we need this functionality?
   - [ ] If yes, implement where? (tmux.conf, ~/bin/, ansible)
   - [ ] If no, use standard tmux + SSH

2. **Dotfile distribution:**
   - [ ] Manual workflow sufficient?
   - [ ] Need automation? If yes, ansible or scripts?
   - [ ] Should all nodes have identical dotfiles?

3. **Cluster management architecture:**
   - [ ] Use SSOT tools in crtr-config?
   - [ ] Implement ansible playbooks?
   - [ ] Keep it simple with ~/bin/ scripts?

4. **Testing strategy:**
   - [ ] Test dotfile changes on crtr before deploying?
   - [ ] How to handle rollback if deploy breaks?
   - [ ] Dry-run mode necessary?

### Immediate Action Items:

- [x] Remove scripts from dotfiles (done 2025-10-21)
- [ ] Complete crtr migration
- [ ] Document current cluster state (which nodes need what)
- [ ] Design cluster management approach
- [ ] Implement chosen approach before migrating drtr/trtr
- [ ] Test cluster management workflow
- [ ] Update MIGRATION-STATUS.md with cluster management plan

---

## References

**Current Documentation:**
- `MIGRATION-STATUS.md` - Overall migration tracking
- `CURRENT-STATE-SUMMARY.md` - Current state overview
- `chezmoi-manifest.md` - Dotfiles architecture

**Removed Scripts (for reference):**
- Original location: `~/.local/share/chezmoi/`
- Git history: Available in dotfiles repo commit history
- Functionality: Documented in this file

**External Resources:**
- ClusterShell: https://clustershell.readthedocs.io/
- Parallel SSH: https://github.com/ParallelSSH/parallel-ssh
- Ansible: https://docs.ansible.com/
- Tmux: https://github.com/tmux/tmux/wiki

---

**Status:** Open for discussion
**Next Step:** Complete crtr migration, then revisit cluster management architecture
**Owner:** crtr (to be discussed after migration complete)
