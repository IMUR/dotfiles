# Record: Promotion Workflow

This record defines the "Hub-and-Spoke" promotion model for updating tools or configurations cluster-wide.

## 🔄 The Promotion Cycle

### 1. Local Exploration (The "Lazy Update")
A user updates a tool or configuration locally on a node (e.g., `trtr`) to verify it works.
- **Example**: `mise upgrade uv` on `trtr` to get version `0.9.28`.

### 2. State Capture
Once verified, the local state must be "Promoted" back to the Git repository.
```bash
# On the node where the change happened (or crtr if file-synced)
chezmoi add ~/.config/mise/config.toml
```

### 3. Repository Commit
The change is committed to the central `dotfiles` repo.
```bash
git add dot_config/mise/config.toml
git commit -m "chore(tools): promote uv to 0.9.28"
git push
```

### 4. Cluster Synchronization
The new "Source of Truth" is pulled and applied to all other nodes.
- **Method A**: Click **Sync** on the DotDash Console for each node.
- **Method B**: Run `chezmoi update` on each node.

## 🛡 Verification Criteria
- **Mismatch Detection**: The DotDash Console should show RED for nodes that haven't synced yet.
- **Health Check**: Nodes should show GREEN once `chezmoi update` completes.
- **Real-World Test**: Run `uv --version` on a synced node to confirm the new version is active.

## 📋 Record Metadata
- **Owner**: Cluster Admin
- **Standard**: Semantic Versioning for Commits
- **Goal**: Minimize divergence between nodes
