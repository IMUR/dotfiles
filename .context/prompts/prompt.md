Conduct a comprehensive bare-metal audit of the cluster's dotfile and tool management systems.

You have passwordless SSH access to all nodes:

- ssh crtr (cooperator, 100.64.0.1)
- ssh drtr (director, 100.64.0.2)
- ssh trtr (terminator, 100.64.0.8)

## CRITICAL: SSH Command Syntax

**Non-interactive SSH does NOT source `.profile`**, so tools in `~/.local/bin` and mise-managed tools won't be in PATH.

**ALWAYS wrap commands in login shell:**
```bash
# WRONG - will fail with "command not found"
ssh crtr 'chezmoi doctor'

# CORRECT - sources full shell config
ssh crtr 'zsh -l -c "chezmoi doctor"'
```

Use this pattern for ALL remote commands in this audit.

## Phase 1: Raw State Collection

Execute these commands on EACH node and capture full output.

### 1.1 System Identity

```bash
ssh crtr 'zsh -l -c "fastfetch --logo none"'
ssh drtr 'zsh -l -c "fastfetch --logo none"'
ssh trtr 'zsh -l -c "fastfetch --logo none"'
```

### 1.2 Chezmoi State

```bash
ssh <node> 'zsh -l -c "
chezmoi doctor
chezmoi source-path
chezmoi status
chezmoi git -- status
chezmoi git -- remote -v
chezmoi git -- log --oneline -5
chezmoi data | head -50
"'
```

### 1.3 Mise State

```bash
ssh <node> 'zsh -l -c "
mise doctor
mise list
mise config
cat ~/.config/mise/config.toml
"'
```

### 1.4 Shell Configuration

```bash
ssh <node> 'zsh -l -c "
echo \"SHELL: \$SHELL\"
\$SHELL --version

# Actual init order (show line numbers for eval/source/init)
grep -n \"eval\|source\|init\" ~/.profile ~/.zshrc ~/.bashrc 2>/dev/null

# Active environment
env | grep -E \"^(PATH|HAS_|MISE_|ZOXIDE_|STARSHIP_)\" | sort
"'
```

### 1.5 Tool Availability

```bash
ssh <node> 'zsh -l -c "which zoxide starship atuin fzf bat eza fd node python go uv bun 2>&1"'
```

### 1.6 Hook Conflicts (zsh only)

```bash
ssh <node> 'zsh -l -i -c "typeset -f chpwd; echo ---; echo \$chpwd_functions"'
```

## Phase 2: Cross-Node Comparison

### 2.1 Chezmoi Source Drift

Compare each node's local chezmoi source against /mnt/ops/dotfiles:

```bash
ssh <node> 'zsh -l -c "diff -rq \$(chezmoi source-path) /mnt/ops/dotfiles --exclude=.git 2>&1"'
```

### 2.2 Template vs Reality

For each node, compare what chezmoi WOULD generate vs what EXISTS:

```bash
ssh <node> 'zsh -l -c "chezmoi diff"'
```

### 2.3 Git State Comparison

Are all nodes tracking the same commits?

```bash
ssh <node> 'zsh -l -c "chezmoi git -- rev-parse HEAD && chezmoi git -- status --porcelain"'
```

## Phase 3: Architecture Analysis

After collecting raw data, analyze:

1. **Source of Truth Question**:
   - Is /mnt/ops/dotfiles the canonical source?
   - Should nodes use local chezmoi or symlink to samba?
   - What's the intended git workflow?

2. **Shell Init Order**:
   - Map the exact sequence: .profile → .zshrc → plugins
   - Identify where mise activates (once? twice?)
   - Identify where zoxide/starship/atuin init
   - Document any hook conflicts

3. **Mise Management**:
   - What tools does mise manage?
   - Are tool versions consistent across nodes?
   - Is mise config in chezmoi or manual?

4. **Drift Inventory**:
   - What local modifications exist per node?
   - Which should be upstreamed to templates?
   - Which are intentionally node-specific?

## Phase 4: Issue Identification

Document every issue found:

| Issue | Node(s) | Severity | Category |
|-------|---------|----------|----------|
| ... | ... | critical/high/medium/low | drift/config/order/missing |

Known symptoms to investigate:

- Persistent zoxide warning about shell configuration
- "Sibling tool call errored" (may be caused by zoxide cwd reset)
- Potential duplicate mise activation (.profile AND .zshrc)
- Non-interactive SSH "command not found" (PATH not set in .zshenv)

## Phase 5: Recommendations

Based on findings, recommend:

1. **Immediate Fixes**: What's broken and blocking?
2. **Architecture Decision**: Single source strategy (symlink vs git-only vs hybrid)
3. **Init Order Fix**: Correct sequence for shell startup
4. **Drift Resolution**: What to upstream, what to discard
5. **Validation Process**: How to verify fixes across all nodes

## Output Format

Create a report file: `CLUSTER-AUDIT-RESULTS.md` in this directory containing:

- Raw command output (collapsible sections)
- Cross-node comparison tables
- Issue inventory
- Recommended fixes with specific file:line references
- Proposed correct init order

Do not fix anything yet. This is investigation only. Present findings for review before any changes.
