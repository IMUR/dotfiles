#!/bin/bash
# Service Deployment Script
# Following validation-first deployment principle

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
SERVICE_NAME="${SERVICE_NAME:-myservice}"
DEPLOY_TARGET="${1:-local}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: $0 [target]"
    echo "  target: local, <node-name>, or all (default: local)"
    echo ""
    echo "Examples:"
    echo "  $0          # Deploy locally"
    echo "  $0 crtr     # Deploy to crtr node"
    echo "  $0 all      # Deploy to all nodes"
}

# Pre-deployment checks
pre_deploy_checks() {
    log_info "Running pre-deployment checks..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check docker-compose.yml exists
    if [ ! -f docker-compose.yml ]; then
        log_error "docker-compose.yml not found"
        exit 1
    fi
    
    # Check .env file
    if [ ! -f .env ]; then
        if [ -f env.template ]; then
            log_warn ".env not found, copying from env.template"
            cp env.template .env
            log_warn "Please edit .env with your configuration"
            exit 1
        else
            log_error ".env file not found and no template available"
            exit 1
        fi
    fi
    
    # Validate compose file
    log_info "Validating docker-compose.yml..."
    if ! docker compose config > /dev/null 2>&1; then
        log_error "docker-compose.yml validation failed"
        docker compose config
        exit 1
    fi
    
    # Check required directories
    log_info "Creating required directories..."
    mkdir -p data/service logs/service data/cache data/database config
    
    log_info "✅ Pre-deployment checks passed"
}

# Deploy locally
deploy_local() {
    log_info "Deploying service locally..."
    
    # Pull latest images
    log_info "Pulling Docker images..."
    docker compose pull
    
    # Show what will change
    log_info "Current service status:"
    docker compose ps
    
    # Deploy with zero-downtime if service exists
    if docker compose ps | grep -q "$SERVICE_NAME"; then
        log_info "Service exists, performing rolling update..."
        docker compose up -d --no-deps --build app
    else
        log_info "Starting service..."
        docker compose up -d
    fi
    
    # Wait for health check
    log_info "Waiting for service to be healthy..."
    sleep 5
    
    # Check health
    if docker compose ps | grep -q "(healthy)"; then
        log_info "✅ Service is healthy"
    else
        log_warn "Service may not be healthy, checking logs..."
        docker compose logs --tail=20
    fi
    
    log_info "✅ Local deployment complete"
}

# Deploy to remote node
deploy_node() {
    local node=$1
    log_info "Deploying service to $node..."
    
    # Check SSH connectivity
    if ! ssh -o ConnectTimeout=5 "$node" "echo 'Connected'" &>/dev/null; then
        log_error "Cannot connect to $node"
        return 1
    fi
    
    # Create remote directory
    ssh "$node" "mkdir -p ~/services/$SERVICE_NAME"
    
    # Copy files to remote
    log_info "Copying files to $node..."
    rsync -av --exclude='.git' --exclude='data' --exclude='logs' ./ "$node:~/services/$SERVICE_NAME/"
    
    # Deploy on remote
    log_info "Starting deployment on $node..."
    ssh "$node" "cd ~/services/$SERVICE_NAME && ./deploy.sh local"
    
    log_info "✅ Deployment to $node complete"
}

# Deploy to all nodes
deploy_all() {
    local nodes=(crtr prtr drtr)
    local failed_nodes=()
    
    log_info "Deploying to all nodes: ${nodes[*]}"
    
    for node in "${nodes[@]}"; do
        if deploy_node "$node"; then
            log_info "✅ $node: Success"
        else
            log_error "❌ $node: Failed"
            failed_nodes+=("$node")
        fi
    done
    
    if [ ${#failed_nodes[@]} -eq 0 ]; then
        log_info "✅ All nodes deployed successfully"
    else
        log_error "Failed nodes: ${failed_nodes[*]}"
        exit 1
    fi
}

# Health check
health_check() {
    log_info "Running health check..."
    
    if [ -x ./healthcheck.sh ]; then
        ./healthcheck.sh
    else
        # Basic health check
        if docker compose ps | grep -q "$SERVICE_NAME.*running"; then
            log_info "✅ Service is running"
            docker compose ps
        else
            log_error "Service is not running"
            docker compose ps
            exit 1
        fi
    fi
}

# Main deployment logic
main() {
    case "$DEPLOY_TARGET" in
        -h|--help)
            show_usage
            exit 0
            ;;
        local)
            pre_deploy_checks
            deploy_local
            health_check
            ;;
        all)
            pre_deploy_checks
            deploy_all
            ;;
        *)
            # Assume it's a node name
            pre_deploy_checks
            deploy_node "$DEPLOY_TARGET"
            ;;
    esac
    
    log_info ""
    log_info "Deployment summary:"
    log_info "  Target: $DEPLOY_TARGET"
    log_info "  Service: $SERVICE_NAME"
    log_info "  Status: ✅ Deployed"
    log_info ""
    log_info "Next steps:"
    log_info "  - Check logs: docker compose logs -f"
    log_info "  - Check health: ./healthcheck.sh"
    log_info "  - Access service: http://localhost:${SERVICE_PORT:-8080}"
}

# Run main
main
