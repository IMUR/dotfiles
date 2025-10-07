# n8n Workflow Automation

**Service Location**: `/cluster-nas/services/n8n/`

## Configuration Files

- `docker-compose.yml` - Container orchestration
- `.env` - Environment variables (secrets)
- `data/` - Persistent data (PostgreSQL + n8n)

## Access

- **URL**: https://n8n.ism.la
- **Local**: http://localhost:5678
- **Database**: PostgreSQL 16 (in container)

## Management

```bash
# Start/stop
cd /cluster-nas/services/n8n
sudo docker compose up -d
sudo docker compose down

# Logs
sudo docker compose logs -f n8n
sudo docker compose logs -f postgres

# Restart
sudo docker compose restart n8n
```

## Environment Variables

See `/cluster-nas/services/n8n/.env` for actual configuration.

Key variables:
- `N8N_HOST=n8n.ism.la`
- `N8N_PROTOCOL=https`
- `N8N_PUSH_BACKEND=websocket`
- `VUE_APP_URL_BASE_API=https://n8n.ism.la/`

## Caddy Configuration

Requires Server-Sent Events (SSE) support:

```caddy
n8n.ism.la {
    reverse_proxy localhost:5678 {
        flush_interval -1
    }
}
```

## Backup

Data location: `/cluster-nas/services/n8n/data/`

Backup strategy:
- PostgreSQL dumps: `docker compose exec postgres pg_dump -U n8n n8n > backup.sql`
- Workflow exports: Use n8n UI export feature
- Full data backup: Copy entire `data/` directory
