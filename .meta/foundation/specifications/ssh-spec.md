# SSH Infrastructure Specification - Co-lab Cluster

**Version:** 1.0
**Date:** 2025-10-09
**Status:** Canonical Reference

## Overview

This document defines the authoritative specification for SSH infrastructure across the Co-lab cluster. All nodes must conform to this specification for consistent, secure, and maintainable cluster access.

## Architecture Principles

### Key Hierarchy

**Two-tier key system:**
1. **Regular keys (`id_ed25519`)** - Inter-node communication
2. **Self keys (`id_ed25519_self`)** - Node-to-self SSH (loopback)

**Rationale:** Separation allows distinct authorization policies and easier key rotation without breaking inter-node dependencies.

### Node Independence

Each node maintains its own:
- Private key pair (`id_ed25519` + `id_ed25519_self`)
- Authorized keys file (identical across cluster)
- SSH config (node-aware via Chezmoi templating)

**No shared private keys.** Each node generates its own keys independently.

## Cluster Topology

### Primary Nodes

| Hostname    | Short | IP              | User | Role         |
|-------------|-------|-----------------|------|--------------|
| cooperator  | crtr  | 192.168.254.10  | crtr | Gateway      |
| projector   | prtr  | 192.168.254.20  | prtr | Compute      |
| director    | drtr  | 192.168.254.30  | drtr | ML Platform  |

### Secondary Nodes

| Hostname    | Short | IP              | User | Role         |
|-------------|-------|-----------------|------|--------------|
| terminator  | trtr  | 192.168.254.40  | trtr | MacBook Air  |
| zerouter    | zrtr  | 192.168.254.11  | zrtr | Router       |

## Key Specification

### Key Types

**Primary:** Ed25519 (modern, secure, fast)
- Algorithm: Ed25519
- Key length: 256 bits (fixed)
- Usage: All new keys, inter-node SSH

**Legacy:** RSA (deprecated, removal planned)
- Algorithm: RSA
- Key length: 2048-4096 bits
- Usage: Backward compatibility only

### Key Naming Convention

```
~/.ssh/id_ed25519         # Inter-node SSH (public key in other nodes' authorized_keys)
~/.ssh/id_ed25519_self    # Self-SSH (public key in own authorized_keys)
~/.ssh/id_rsa             # DEPRECATED - Legacy RSA key
```

### Key Generation

**Inter-node key:**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "$(whoami)@$(hostname)"
```

**Self-SSH key:**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_self -C "$(whoami)-self-ssh"
```

**Comment format:**
- Inter-node: `user@hostname` (e.g., `crtr@cooperator`)
- Self-SSH: `user-self-ssh` (e.g., `crtr-self-ssh`)

## Authorized Keys Specification

### Structure

Each node must have **exactly 6 authorized keys** in this order:

1. Personal access key (`rjallen22@gmail.com`)
2. Cooperator key (self or inter-node based on current node)
3. Projector key (self or inter-node based on current node)
4. Director key (self or inter-node based on current node)
5. Terminator key
6. Zerouter key

### Node-Specific Variations

**On cooperator (crtr):**
```
ssh-ed25519 <key> rjallen22@gmail.com
ssh-ed25519 <key> crtr@cooperator          # SELF KEY
ssh-ed25519 <key> prtr@projector
ssh-ed25519 <key> drtr@director
ssh-ed25519 <key> trtr@terminator
ssh-ed25519 <key> zrtr@zerouter
```

**On projector (prtr):**
```
ssh-ed25519 <key> rjallen22@gmail.com
ssh-ed25519 <key> crtr@cooperator
ssh-ed25519 <key> prtr@projector          # SELF KEY
ssh-ed25519 <key> drtr@director
ssh-ed25519 <key> trtr@terminator
ssh-ed25519 <key> zrtr@zerouter
```

**On director (drtr):**
```
ssh-ed25519 <key> rjallen22@gmail.com
ssh-ed25519 <key> crtr@cooperator
ssh-ed25519 <key> prtr@projector
ssh-ed25519 <key> drtr@director          # SELF KEY
ssh-ed25519 <key> trtr@terminator
ssh-ed25519 <key> zrtr@zerouter
```

### Invariants

- **No duplicate keys** - Each fingerprint appears exactly once
- **No RSA keys** - Ed25519 only (RSA being phased out)
- **Strict ordering** - Keys must appear in specified order
- **Exact count** - Must be exactly 6 keys, no more, no less

## SSH Config Specification

### Global Settings

Applied to all SSH connections:

```ssh-config
Host *
    SetEnv TERM=xterm-256color
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
```

**ControlMaster:** Connection multiplexing for performance
- Shares single connection across multiple sessions
- Reduces authentication overhead
- Persists for 10 minutes after last use
- Requires `~/.ssh/sockets/` directory to exist

### Node-Specific Configuration

**Key Selection Logic:**
- **Self-SSH:** When connecting to own hostname → use `id_ed25519_self`
- **Inter-node SSH:** When connecting to other nodes → use `id_ed25519`

**Implementation:** Chezmoi template conditionals based on `.chezmoi.hostname`

**Example for cooperator:**
```ssh-config
{{- if eq .chezmoi.hostname "cooperator" }}
Host crtr
    HostName 192.168.254.10
    User crtr
    IdentityFile ~/.ssh/id_ed25519_self  # SELF KEY
{{- else }}
Host crtr
    HostName 192.168.254.10
    User crtr
    IdentityFile ~/.ssh/id_ed25519      # INTER-NODE KEY
{{- end }}
```

### Host Entries

All nodes must define:
- crtr (node-aware self/inter-node key)
- prtr (node-aware self/inter-node key)
- drtr (node-aware self/inter-node key)
- zrtr (always inter-node key)
- trtr (always inter-node key)

## Security Requirements

### Private Key Protection

- **Permissions:** `600` (owner read/write only)
- **Location:** `~/.ssh/` only
- **Backup:** Never commit to version control
- **Distribution:** Never copy private keys between nodes

### Authorized Keys Protection

- **Permissions:** `600` (owner read/write only)
- **Management:** Managed via deployment scripts only
- **Validation:** Must match specification exactly

### Known Hosts

- **Auto-populate:** Each node must have its own IP in known_hosts
- **Format:** Hashed entries preferred (`ssh-keyscan -H`)
- **Coverage:** All cluster nodes + self

## File Locations

### Private Keys
```
~/.ssh/id_ed25519          # Primary inter-node key (600)
~/.ssh/id_ed25519_self     # Self-SSH key (600)
~/.ssh/id_ed25519.pub      # Public key (644)
~/.ssh/id_ed25519_self.pub # Self public key (644)
```

### Configuration
```
~/.ssh/config              # SSH client config (644)
~/.ssh/authorized_keys     # Public keys authorized to SSH in (600)
~/.ssh/known_hosts         # Known host fingerprints (644)
```

### ControlMaster
```
~/.ssh/sockets/            # Socket directory (700)
~/.ssh/sockets/%r@%h:%p    # Connection sockets (600, auto-created)
```

## Management & Deployment

### Initial Setup (New Node)

1. Generate key pair:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "$(whoami)@$(hostname)"
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_self -C "$(whoami)-self-ssh"
   ```

2. Distribute public key to cluster admin
3. Receive canonical authorized_keys file
4. Apply SSH config via chezmoi:
   ```bash
   chezmoi apply
   ```

5. Create socket directory:
   ```bash
   mkdir -p ~/.ssh/sockets
   chmod 700 ~/.ssh/sockets
   ```

6. Verify connectivity:
   ```bash
   ssh crtr echo "test"
   ssh $(hostname) echo "self-test"
   ```

### Key Rotation

**When rotating inter-node key:**
1. Generate new `id_ed25519` on source node
2. Distribute new public key to cluster admin
3. Update all nodes' `authorized_keys` files
4. Test connectivity from rotated node
5. Remove old key from authorized_keys after verification

**When rotating self key:**
1. Generate new `id_ed25519_self` on node
2. Update own `authorized_keys` file
3. Test self-SSH
4. No other nodes affected

### Adding New Node

1. New node generates keys (per Initial Setup)
2. Collect public keys from new node
3. Add new node's inter-node key to all existing nodes' authorized_keys
4. Add all existing nodes' inter-node keys + new node's self key to new node's authorized_keys
5. Deploy updated SSH configs to all nodes
6. Verify bidirectional connectivity

### Removing Node

1. Remove node's public key from all authorized_keys files
2. Remove node's Host entry from SSH configs
3. Deploy updated configs cluster-wide
4. Archive removed node's keys securely (do not delete immediately)

## Validation & Testing

### Validation Script Requirements

Must verify:
- Key count: exactly 6 per node
- Key types: all Ed25519 (no RSA)
- Key uniqueness: no duplicate fingerprints
- Key ordering: matches specification
- File permissions: 600 for private keys, authorized_keys
- Socket directory: exists with 700 permissions
- SSH config: syntax valid, contains required hosts

### Connectivity Testing

**Inter-node connectivity matrix:**
```
     crtr  prtr  drtr
crtr  [S]   [X]   [X]
prtr  [X]   [S]   [X]
drtr  [X]   [X]   [S]
```
- `[X]` = Inter-node SSH must work
- `[S]` = Self-SSH must work

**Test command:**
```bash
for node in crtr prtr drtr; do
    ssh $node "echo \"✅ $(hostname) → $node\""
done
```

## Troubleshooting

### Common Issues

**"Permission denied (publickey)"**
- Check authorized_keys contains correct public key
- Verify private key exists and has correct permissions (600)
- Confirm SSH config specifies correct IdentityFile

**"Host key verification failed"**
- Add host to known_hosts: `ssh-keyscan -H <ip> >> ~/.ssh/known_hosts`
- Or accept on first connection

**"unix_listener: cannot bind to path"**
- Create socket directory: `mkdir -p ~/.ssh/sockets`
- Check permissions: `chmod 700 ~/.ssh/sockets`

**Self-SSH fails but inter-node works**
- Verify `id_ed25519_self` public key is in own authorized_keys
- Check SSH config uses `id_ed25519_self` for self-host entry

## Version History

- **1.0** (2025-10-09) - Initial specification
  - Two-tier key system established
  - 6-key canonical authorized_keys format
  - ControlMaster connection multiplexing
  - Node-aware SSH config templating

## References

- OpenSSH Documentation: https://www.openssh.com/manual.html
- Ed25519 Specification: RFC 8032
- SSH Config Format: `man ssh_config`
- Chezmoi Templating: https://www.chezmoi.io/user-guide/templating/

---

**Authority:** This document is the canonical reference for SSH infrastructure.
**Maintenance:** Updates require review and approval before deployment.
**Enforcement:** Automated validation enforces compliance with this specification.
