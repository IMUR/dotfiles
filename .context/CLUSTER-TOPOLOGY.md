# Cluster Topology

| Node | Hostname | Tailscale IP | Role | Architecture | OS |
|------|----------|--------------|------|--------------|----|
| **crtr** | cooperator | 100.64.0.1 | Gateway / NFS Host | aarch64 | Linux (Ubuntu) |
| **drtr** | director | 100.64.0.2 | GPU Compute | x86_64 | Linux (Debian) |
| **trtr** | projector | 100.64.0.8 | Workstation | aarch64 | macOS |

## 🔗 Connectivity
- Nodes communicate via **Tailscale** on the `100.64.0.x` subnet.
- **Passwordless SSH** is enabled from `crtr` to all other nodes.
- **NFS** shares are mounted from `crtr` to provide shared storage across the cluster.

## 🛠 Management
- **Configuration**: Chezmoi
- **Tools**: Mise
- **Monitoring**: DotDash Console (`http://100.64.0.1:8000`)
