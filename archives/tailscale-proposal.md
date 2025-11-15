# Self-Hosted VPN and Network Configuration Guide

This document explains how to set up a secure, self-hosted cluster network using Tailscale/Headscale for VPN and Pi-hole for DNS and DHCP management, while enabling public access via DuckDNS.

---

## 1. Network Components

- **Raspberry Pi (Edge Node):** Runs Pi-hole (DHCP/DNS) and Headscale (self-hosted Tailscale control server).
- **Cluster Nodes:** Each node runs the Tailscale client, connecting to the Headscale server.
- **Public Access Services:** Managed through DuckDNS (dynamic DNS) and a reverse proxy (e.g., Caddy or NGINX) for HTTPS/HTTP/SSH.

---

## 2. VPN Setup

- **Install Headscale** on the Raspberry Pi (only needs to run on one device).
- **Install Tailscale Client** on all cluster nodes, including the Pi itself.
- **Configure Tailscale Clients** to connect to the Headscale server instead of Tailscale’s cloud.

---

## 3. Network Address Management

- Assign a **static IP** to the Raspberry Pi running Pi-hole (either manually or via DHCP reservation, but outside the DHCP pool).
- **Disable DHCP** on the router/gateway.
- **Enable DHCP** in Pi-hole to serve IP addresses to all network devices.
- **Set Router DNS** to the Pi-hole static IP.

---

## 4. DNS Configuration

- Pi-hole acts as your network’s DNS server, managing external and internal name resolution.
- For custom internal domains, use Pi-hole’s local DNS records.
- For Tailscale-connected devices, optionally enable MagicDNS for seamless device naming.

---

## 5. Port Forwarding/Public Services

- On your router, **forward necessary ports** (e.g., 80 for HTTP, 443 for HTTPS, 22 for SSH) to the Raspberry Pi or the device running your public-facing services.
- **DuckDNS** is used to maintain a consistent public domain for remote access.
- Reverse proxy (Caddy/NGINX) handles SSL certificates and routes incoming connections.

---

## 6. External and Internal Access

- **Internal Access (Secure):** Use Tailscale/Headscale mesh VPN for private device connectivity.
- **External Access:** Use DuckDNS for public-facing services, with router port forwarding.

---

## 7. Key Considerations

- **Pi-hole must have a fixed/static IP** for reliability.
- **Router swap-out:** Re-apply port forwards and verify DNS points to Pi-hole.
- **DHCP scope:** Ensure Pi-hole’s DHCP pool does not overlap with manually assigned static IPs.
- **DNS redundancy:** Most internal resolution handled via Pi-hole/Tailscale; DuckDNS for external.

---

## 8. Security Practices

- Lock sensitive services, like admin consoles or internal APIs, behind the VPN.
- Only expose necessary public services via DuckDNS and reverse proxy.

---

## Quick Checklist:

- [x] Pi-hole running at static IP
- [x] Headscale running on Pi
- [x] Tailscale installed/configured on all nodes
- [x] DHCP enabled on Pi-hole, disabled on router
- [x] Router DNS set to Pi-hole
- [x] Ports forwarded for public services
- [x] DuckDNS domain configured/updating
- [x] Reverse proxy routing public requests

---

**This setup gives you secure, seamless connectivity between all your cluster devices, robust DNS ad-blocking, managed public access, and the flexibility to self-host every key service without dependency on external cloud providers.**
