# Service Deployment Template

Template for deploying a containerized service to the cluster.

## Structure

```
service/
├── README.md              # This file
├── docker-compose.yml     # Service definition
├── .env.template         # Environment variables template
├── config/               # Service configuration files
├── scripts/              # Service management scripts
├── healthcheck.sh        # Health check script
└── deploy.sh            # Deployment script
```

## Quick Start

1. **Copy template to your service directory:**
   ```bash
   cp -r /path/to/template ~/services/my-service/
   cd ~/services/my-service/
   ```

2. **Configure the service:**
   ```bash
   # Edit service definition
   vim docker-compose.yml
   
   # Set environment variables
   cp .env.template .env
   vim .env
   ```

3. **Deploy the service:**
   ```bash
   ./deploy.sh
   ```

## Configuration

### docker-compose.yml
Modify the service definition for your application:
```yaml
services:
  app:
    image: your-app:latest
    ports:
      - "8080:80"
    environment:
      - NODE_ENV=production
```

### Environment Variables
Copy `.env.template` to `.env` and set your values:
```bash
SERVICE_NAME=my-service
SERVICE_PORT=8080
LOG_LEVEL=info
```

### Configuration Files
Place service-specific configuration in `config/`:
- `config/app.yml` - Application configuration
- `config/nginx.conf` - Web server configuration
- `config/database.yml` - Database configuration

## Deployment

### Single Node
Deploy to a specific node:
```bash
./deploy.sh <node-name>
```

### All Nodes
Deploy to all cluster nodes:
```bash
./deploy.sh all
```

### Rolling Update
Update service with zero downtime:
```bash
./scripts/rolling-update.sh
```

## Health Monitoring

The template includes health checking:
```bash
# Manual health check
./healthcheck.sh

# Automated monitoring (add to crontab)
*/5 * * * * /path/to/service/healthcheck.sh
```

## Backup and Recovery

### Backup
```bash
./scripts/backup.sh
```

### Restore
```bash
./scripts/restore.sh <backup-file>
```

## Troubleshooting

### View Logs
```bash
docker compose logs -f
```

### Restart Service
```bash
docker compose restart
```

### Full Reset
```bash
docker compose down -v
docker compose up -d
```

## Customization

### Adding Dependencies
Edit `docker-compose.yml` to add dependent services:
```yaml
services:
  app:
    depends_on:
      - database
      - cache
  
  database:
    image: postgres:14
    
  cache:
    image: redis:7
```

### Scaling
Adjust replica count:
```yaml
services:
  app:
    deploy:
      replicas: 3
```

### Resource Limits
Set resource constraints:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '2G'
```

## Best Practices

1. **Always use `.env.template`** - Never commit `.env` files
2. **Version your images** - Avoid `:latest` in production
3. **Health checks are mandatory** - Define proper health endpoints
4. **Log to stdout** - Let Docker handle log management
5. **One service per container** - Follow single responsibility
6. **Use volumes for persistence** - Don't store data in containers
7. **Document everything** - Especially environment variables

## Integration

This template integrates with:
- Cluster monitoring (Prometheus/Grafana)
- Central logging (ELK/Loki)
- Backup systems
- CI/CD pipelines

## Support

For issues:
1. Check logs: `docker compose logs`
2. Verify configuration: `docker compose config`
3. Test health: `./healthcheck.sh`
4. Review documentation in `docs/`
