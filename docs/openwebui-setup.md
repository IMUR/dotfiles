# OpenWebUI + Ollama + SearXNG + Jupyter Setup Guide

**Date:** 2025-10-29
**Node:** cooperator (192.168.254.10)
**Inference Node:** director (192.168.254.30)

## Architecture

```
crtr (Edge Node - 192.168.254.10):
├── Caddy (reverse proxy)
├── OpenWebUI (localhost:8082)
├── SearXNG (localhost:8083)
└── Jupyter (0.0.0.0:8888)

drtr (Compute Node - 192.168.254.30):
└── Ollama (0.0.0.0:11434)
    └── dolphin-mistral:7b-v2.8-q6_K (~5.9GB)
```

---

## 1. OpenWebUI Installation (crtr)

### Deploy Container
```bash
docker run -d \
  --name openwebui \
  --restart unless-stopped \
  -p 127.0.0.1:8082:8080 \
  -v /home/crtr/docker/openwebui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main
```

**Key Points:**
- Bind to localhost only (127.0.0.1:8082)
- Data persists in `/home/crtr/docker/openwebui/`
- **No environment variables needed** - configure via admin UI
- Environment variables can corrupt the database and break functionality

### Caddy Configuration
**Critical:** OpenWebUI requires HTTP/1.1 for WebSocket support.

File: `/etc/caddy/Caddyfile`
```caddy
cht.ism.la {
    reverse_proxy localhost:8082 {
        transport http {
            versions 1.1
        }
    }
}
```

**Without `versions 1.1`:** WebSocket connections fail with "Unsupported upgrade request" error, causing "Unexpected token 'd', data: {" JSON parsing errors in the browser.

**Do not add extra header forwarding** (`header_up Upgrade`, `header_up Connection`) - this breaks WebSocket connections. The simple HTTP/1.1 enforcement is sufficient.

Reload Caddy:
```bash
sudo systemctl reload caddy
```

### DNS Configuration
Add to `/etc/hosts` on all cluster nodes (crtr, drtr, prtr, trtr):
```
192.168.254.10 cht.ism.la  # OpenWebUI chat interface
192.168.254.10 sch.ism.la  # SearXNG search engine
```

**Why needed:** Without local DNS entries, domains resolve to external IP (47.154.23.175), causing NAT hairpinning issues and connection timeouts from within the network.

**For permanent cluster-wide access:** Add to Pi-hole Local DNS:
```bash
echo "192.168.254.10 cht.ism.la" | sudo tee -a /etc/pihole/custom.list
echo "192.168.254.10 sch.ism.la" | sudo tee -a /etc/pihole/custom.list
sudo pihole restartdns reload-lists
```

---

## 2. Ollama Installation (drtr)

### Install Ollama
```bash
ssh drtr
curl -fsSL https://ollama.com/install.sh | sh
```

### Configure Network Binding
**Critical:** Ollama defaults to localhost only. Configure to listen on all interfaces:

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

**Why 0.0.0.0:** OpenWebUI on crtr needs network access to Ollama. Default 127.0.0.1 binding only allows local connections.

### Pull Model
```bash
ollama pull dolphin-mistral:7b-v2.8-q6_K
```

**Model Selection for RTX 2080 (8GB VRAM):**
- `dolphin-mistral:7b-v2.8-q6_K` (~5.9GB) - Uncensored, high quality
- Alternative: `wizard-vicuna-uncensored:13b-q4_K_M` (~7.4GB)

### Verify
```bash
# From drtr
ollama list

# From crtr (test network access)
curl http://192.168.254.30:11434/api/tags
```

---

## 3. OpenWebUI Configuration

Access: `https://cht.ism.la` or `http://localhost:8082`

### Connect to Ollama Backend
1. Admin Panel → **Connections** → **Manage Ollama API Connections**
2. Add URL: `http://192.168.254.30:11434`
3. Save

**Do not use environment variables** - configure via UI only. Environment variables can break OpenWebUI's database and cause persistent errors.

---

## 4. SearXNG Installation (crtr)

### Deploy Container
```bash
docker run -d \
  --name searxng \
  --restart unless-stopped \
  -p 127.0.0.1:8083:8080 \
  -v /home/crtr/docker/searxng:/etc/searxng \
  -e SEARXNG_BASE_URL=https://sch.ism.la/ \
  searxng/searxng:latest
```

### Enable JSON Format
**Critical:** OpenWebUI requires JSON responses.

```bash
docker exec searxng sh -c "sed -i '/^  formats:/,/^    - html$/c\\  formats:\n    - html\n    - json' /etc/searxng/settings.yml"
docker restart searxng
```

Verify:
```bash
curl "http://localhost:8083/search?q=test&format=json" | python3 -m json.tool | head -20
```

### Caddy Configuration
File: `/etc/caddy/Caddyfile`
```caddy
sch.ism.la {
    reverse_proxy localhost:8083
}
```

Reload:
```bash
sudo systemctl reload caddy
```

---

## 5. Jupyter Installation (crtr)

### Deploy Container
```bash
mkdir -p /home/crtr/docker/jupyter

JUPYTER_TOKEN=$(openssl rand -hex 32)
echo "${JUPYTER_TOKEN}" > /home/crtr/docker/jupyter/.token
chmod 600 /home/crtr/docker/jupyter/.token

docker run -d \
  --name jupyter \
  --restart unless-stopped \
  -p 0.0.0.0:8888:8888 \
  -v /home/crtr/docker/jupyter:/home/jovyan/work \
  -e JUPYTER_ENABLE_LAB=yes \
  -e JUPYTER_TOKEN="${JUPYTER_TOKEN}" \
  jupyter/minimal-notebook:latest

echo "Jupyter token: ${JUPYTER_TOKEN}"
```

**Key Points:**
- **Bind to 0.0.0.0:8888** - OpenWebUI container needs network access
- Token stored in `/home/crtr/docker/jupyter/.token`
- JupyterLab enabled by default
- Data persists in `/home/crtr/docker/jupyter/`

### Verify
```bash
# Check token
cat /home/crtr/docker/jupyter/.token

# Test API
curl "http://localhost:8888/api?token=$(cat /home/crtr/docker/jupyter/.token)"

# Test from OpenWebUI container (via Docker bridge)
docker exec openwebui curl -I http://172.17.0.1:8888
```

---

## 6. OpenWebUI Code Execution Configuration

### Access Settings
Admin Panel → **Settings** → **Code Execution**

### Configuration

**Code Execution Engine:** `jupyter`

**Jupyter URL:** `http://172.17.0.1:8888`
- **Not `localhost:8888`** - "localhost" inside OpenWebUI container refers to the container itself
- Use Docker bridge IP `172.17.0.1` to reach host services

**Jupyter Auth:** `Token` (select from dropdown)

**Token Field:** (paste token from `/home/crtr/docker/jupyter/.token`)

**Code Execution Timeout:** `60` (seconds)

### Also Configure Code Interpreter
Scroll down to **Code Interpreter** section and repeat the same settings:
- Engine: `jupyter`
- URL: `http://172.17.0.1:8888`
- Auth: `Token`
- Token: (same token)

---

## 7. Web Search Integration

### OpenWebUI Configuration
Admin Panel → **Settings** → **Web Search**

**Query URL:** `https://sch.ism.la/search?q=<query>&format=json`
- Use HTTPS domain (works now that hosts file entries are added)

**Alternative (for containers without DNS access):**
- URL: `http://localhost:8083/search?q=<query>&format=json`
- Only works if SearXNG and OpenWebUI are on same host

**Engine Type:** `SearXNG`

---

## 8. Verification

### Test Stack from crtr
```bash
# OpenWebUI
curl -I http://localhost:8082

# Ollama (on drtr)
curl http://192.168.254.30:11434/api/tags

# SearXNG
curl "http://localhost:8083/search?q=test&format=json"

# Jupyter
curl "http://localhost:8888/api?token=$(cat /home/crtr/docker/jupyter/.token)"

# Through Caddy
curl -I https://cht.ism.la
curl -I https://sch.ism.la
```

### Test from Other Nodes
```bash
ssh trtr 'curl -I https://cht.ism.la'
ssh trtr 'curl -I https://sch.ism.la'
```

If these fail with timeout, DNS is resolving to external IP - hosts file entries are missing on that node.

### Test in Browsers
**All browsers (Chrome, Firefox, Safari):**
- Visit `https://cht.ism.la`
- Start a chat - should connect without errors
- Enable web search - should return results
- Try code execution - should run Python code

**Safari-specific:** May initially show WebSocket errors, but a Caddy reload usually resolves them. The simple HTTP/1.1 configuration works for all browsers.

---

## 9. Troubleshooting

### WebSocket Issues
**Symptom:** "Unexpected token 'd', data: {" error in browser console, "Unsupported upgrade request" in OpenWebUI logs.

**Cause:** Caddy using HTTP/2 CONNECT method, OpenWebUI only supports HTTP/1.1 WebSocket upgrades.

**Fix:** Force HTTP/1.1 in Caddy (see Section 1). Do not add extra header forwarding.

**Safari-specific:** Safari is stricter about WebSocket handshakes. If issues persist after HTTP/1.1 enforcement, try reloading Caddy: `sudo systemctl reload caddy`

### Jupyter Connection Failed
**Symptom:** "Error: Cannot connect to host localhost:8888" in OpenWebUI.

**Cause:** Using `localhost` instead of Docker bridge IP.

**Fix:** Use `http://172.17.0.1:8888` in OpenWebUI settings, not `localhost:8888`.

**Verify Docker bridge IP:**
```bash
ip addr show docker0 | grep 'inet ' | awk '{print $2}'  # Should show 172.17.0.1/16
```

### Web Search DNS Errors
**Symptom:** "Failed to resolve 'sch.ism.la'" in OpenWebUI logs.

**Cause:** DNS resolving to external IP, or container can't resolve domain.

**Fix Option 1:** Use localhost URL: `http://localhost:8083/search?q=<query>&format=json`

**Fix Option 2:** Add hosts file entries on all nodes (preferred for cluster-wide access).

### Web Search Returns HTML Instead of JSON
**Symptom:** 403 Forbidden or HTML responses instead of JSON.

**Cause:** SearXNG not configured for JSON format.

**Fix:** Enable JSON in settings.yml (see Section 4).

### Model Not Found in OpenWebUI
**Symptom:** OpenWebUI shows no models available.

**Verify:**
```bash
# On drtr
ollama list

# Network test from crtr
curl http://192.168.254.30:11434/api/tags
```

**Common causes:**
- Ollama not listening on network (check override.conf)
- Firewall blocking port 11434
- Wrong URL in OpenWebUI settings

### Database Corruption After Environment Variables
**Symptom:** OpenWebUI features not working, persistent errors even after disabling features.

**Cause:** Environment variables corrupted the database.

**Fix:**
```bash
docker stop openwebui
mv /home/crtr/docker/openwebui/webui.db /home/crtr/docker/openwebui/webui.db.backup-$(date +%Y%m%d-%H%M%S)
docker start openwebui
```

Then reconfigure via admin UI only.

---

## 10. Critical Configuration Points

### Must-Have Settings
1. **Caddy HTTP/1.1**: Required for WebSocket support (OpenWebUI)
2. **Ollama Network Binding**: Must listen on 0.0.0.0:11434, not 127.0.0.1
3. **Jupyter Network Binding**: Must listen on 0.0.0.0:8888 for container access
4. **Docker Bridge IP**: Use 172.17.0.1 from containers to reach host services
5. **SearXNG JSON Format**: Must be explicitly enabled in settings.yml
6. **DNS Local Resolution**: Domains must resolve to 192.168.254.10 internally
7. **No Environment Variables**: Configure OpenWebUI via admin UI only

### Common Mistakes
- ❌ Using `localhost` from containers (use 172.17.0.1)
- ❌ Adding environment variables to OpenWebUI (use admin UI)
- ❌ Missing hosts file entries (causes DNS to external IP)
- ❌ Adding extra WebSocket headers to Caddy (breaks connections)
- ❌ Forgetting to enable JSON format in SearXNG
- ❌ Binding services to 127.0.0.1 when remote access needed

---

## 11. File Locations

### crtr
- OpenWebUI data: `/home/crtr/docker/openwebui/`
  - Database: `webui.db`
  - Uploads: `uploads/`
- SearXNG config: `/home/crtr/docker/searxng/`
  - Settings: `settings.yml`
- Jupyter data: `/home/crtr/docker/jupyter/`
  - Token: `.token`
  - Notebooks: `work/`
- Caddy config: `/etc/caddy/Caddyfile`
- Hosts file: `/etc/hosts`

### drtr
- Ollama models: `/usr/share/ollama/.ollama/models`
- Ollama config: `/etc/systemd/system/ollama.service.d/override.conf`

---

## 12. Service Management

### Start/Stop/Restart
```bash
# OpenWebUI
docker stop openwebui
docker start openwebui
docker restart openwebui

# SearXNG
docker restart searxng

# Jupyter
docker restart jupyter

# Ollama (on drtr)
ssh drtr 'sudo systemctl restart ollama'

# Caddy
sudo systemctl reload caddy   # Reload config without downtime
sudo systemctl restart caddy  # Full restart
```

### Logs
```bash
# OpenWebUI
docker logs openwebui --tail 50 --follow

# SearXNG
docker logs searxng --tail 50 --follow

# Jupyter
docker logs jupyter --tail 50 --follow

# Ollama (on drtr)
ssh drtr 'sudo journalctl -u ollama -f'

# Caddy
sudo journalctl -u caddy -f
```

### Check Status
```bash
# All containers on crtr
docker ps --filter name="openwebui|searxng|jupyter"

# Ollama on drtr
ssh drtr 'systemctl status ollama'

# Caddy on crtr
sudo systemctl status caddy
```

---

## 13. Docker Networking Notes

### Understanding Container Networking
- **Containers → Localhost services**: Use `172.17.0.1` (Docker bridge IP)
- **Host → Containers**: Use `localhost` with mapped ports
- **Containers → Containers**: Use container names or bridge IP
- **External → Services**: Domain resolves to public IP, router forwards to crtr

### Why 172.17.0.1?
Inside a Docker container:
- `localhost` = the container itself
- `127.0.0.1` = the container itself
- `172.17.0.1` = the Docker host machine
- `host.docker.internal` = Docker host (on some platforms)

### Port Binding Strategies
- **127.0.0.1:PORT** - Only accessible from host machine (OpenWebUI, SearXNG)
- **0.0.0.0:PORT** - Accessible from network (Jupyter, Ollama)

---

## 14. Browser Compatibility

### Tested Browsers
✅ **Chrome/Chromium** (all platforms) - Full support
✅ **Firefox** (all platforms) - Full support
✅ **Safari** (macOS and iOS) - Full support with HTTP/1.1 enforcement

### Safari Considerations
Safari requires HTTP/1.1 enforcement in Caddy for WebSocket connections. The configuration in Section 1 works for all browsers including Safari. Do not add extra header forwarding directives as they break functionality in all browsers.

---

## 15. Security Considerations

### Token Management
- **Jupyter token**: 32-byte hex, stored in `/home/crtr/docker/jupyter/.token`
- Keep token secure - grants code execution access
- Consider rotating token periodically

### Network Exposure
- **OpenWebUI**: Localhost only (127.0.0.1:8082), proxied via Caddy with SSL
- **SearXNG**: Localhost only (127.0.0.1:8083), proxied via Caddy with SSL
- **Jupyter**: All interfaces (0.0.0.0:8888), token-protected, not exposed via Caddy
- **Ollama**: All interfaces (0.0.0.0:11434), internal network only

### Recommendations
1. Jupyter is exposed on network without SSL - only use on trusted networks
2. Consider adding Jupyter to Caddy if external access needed
3. Rotate Jupyter token regularly
4. Monitor Docker logs for suspicious activity

---

## 16. Performance Notes

### Resource Usage (crtr - 16GB RAM)
- **OpenWebUI**: ~400MB RAM, minimal CPU
- **SearXNG**: ~100MB RAM, minimal CPU
- **Jupyter**: ~500MB RAM (idle), varies with notebooks
- **Total overhead**: ~1GB RAM with all services running

### Inference Performance (drtr - RTX 2080, 8GB VRAM)
- **dolphin-mistral:7b-v2.8-q6_K**: ~30-40 tokens/sec
- **Model loads**: ~5-10 seconds cold start
- **VRAM usage**: ~6GB for model + context

---

## 17. Future Enhancements

### Potential Improvements
- [ ] Add Jupyter to Caddy reverse proxy with domain (e.g., `jpy.ism.la`)
- [ ] Implement Jupyter token rotation script
- [ ] Deploy larger models on drtr (13B, 30B variants)
- [ ] Add GPU-accelerated Jupyter kernels on drtr
- [ ] Implement RAG (Retrieval Augmented Generation) with local documents
- [ ] Add monitoring/metrics dashboard

### Migration Considerations
If moving Jupyter to drtr (GPU node):
1. Similar setup pattern - Docker container with token auth
2. Update OpenWebUI URL to `http://192.168.254.30:8888`
3. Ensure 0.0.0.0 binding for network access
4. Consider Caddy proxy for SSL termination

---

## 18. Lessons Learned

### Key Takeaways from Setup
1. **Docker networking is subtle**: `localhost` means different things in different contexts
2. **Environment variables are dangerous**: OpenWebUI should only be configured via UI
3. **WebSocket configuration matters**: HTTP/1.1 enforcement critical for OpenWebUI
4. **DNS matters internally**: Hosts file entries prevent NAT hairpinning issues
5. **Safari is strict**: But works fine with proper HTTP/1.1 configuration
6. **Simplest solution wins**: Minimal Caddy config better than complex header forwarding
7. **Token-based auth works**: Secure and simple for Jupyter integration

### Debugging Tips
- Always check Docker logs first: `docker logs <container> --tail 50`
- Test localhost before testing domains
- Verify DNS resolution: `curl -I <domain>` from different nodes
- Check Docker networking: `docker exec <container> curl <url>`
- Browser developer console shows WebSocket errors clearly
- Caddy logs reveal proxy/SSL issues: `sudo journalctl -u caddy -f`

---

## 19. References

### Documentation Links
- [OpenWebUI Documentation](https://docs.openwebui.com/)
- [Ollama Documentation](https://ollama.com/docs)
- [SearXNG Documentation](https://docs.searxng.org/)
- [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/)
- [Caddy Documentation](https://caddyserver.com/docs/)

### Related Files in This Repository
- [SYSTEM-STATE.md](/SYSTEM-STATE.md) - Current cluster state
- [ssot/state/services.yml](/ssot/state/services.yml) - Service definitions
- [ssot/state/domains.yml](/ssot/state/domains.yml) - Domain routing
- [ssot/state/network.yml](/ssot/state/network.yml) - Network configuration

---

**Last Updated:** 2025-10-29
**Tested and Verified:** All functionality working across Chrome, Firefox, and Safari on macOS and iOS, with remote and local network access confirmed.
