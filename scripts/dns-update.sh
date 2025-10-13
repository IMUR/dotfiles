#!/usr/bin/env bash
# GoDaddy DNS Manager for ism.la
# Uses GoDaddy REST API to manage DNS records
# Requires: curl, jq

set -euo pipefail

# Configuration
DOMAIN="${GODADDY_DOMAIN:-ism.la}"
API_KEY="${GODADDY_API_KEY:-}"
API_SECRET="${GODADDY_API_SECRET:-}"
API_ENV="${GODADDY_API_ENV:-OTE}"  # OTE for test, PRODUCTION for live

# API Endpoints
if [[ "$API_ENV" == "OTE" ]]; then
    API_BASE="https://api.ote-godaddy.com"
else
    API_BASE="https://api.godaddy.com"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Zone file path
ZONE_FILE="ism.la.txt"

# Helper functions
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_dependencies() {
    local missing=()
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
    fi
}

check_credentials() {
    if [[ -z "$API_KEY" ]] || [[ -z "$API_SECRET" ]]; then
        error "GoDaddy API credentials not set. Set GODADDY_API_KEY and GODADDY_API_SECRET environment variables."
    fi
}

api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    
    local url="${API_BASE}${endpoint}"
    local auth_header="sso-key ${API_KEY}:${API_SECRET}"
    
    if [[ -n "$data" ]]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: $auth_header" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: $auth_header"
    fi
}

# Commands
cmd_list() {
    info "Fetching DNS records for $DOMAIN from $API_ENV environment..."
    
    local response
    response=$(api_call "GET" "/v1/domains/$DOMAIN/records")
    
    if echo "$response" | jq -e . >/dev/null 2>&1; then
        # Format output with printf instead of column command
        printf "%-8s %-20s %-40s %s\n" "TYPE" "NAME" "DATA" "TTL"
        echo "$response" | jq -r '.[] | "\(.type)\t\(.name)\t\(.data)\t\(.ttl)"' | \
        while IFS=$'\t' read -r type name data ttl; do
            printf "%-8s %-20s %-40s %s\n" "$type" "$name" "$data" "$ttl"
        done
        success "Retrieved $(echo "$response" | jq length) records"
    else
        error "Failed to fetch records: $response"
    fi
}

cmd_list_type() {
    local record_type="${1:-}"
    if [[ -z "$record_type" ]]; then
        error "Record type required. Usage: $0 list-type <TYPE>"
    fi
    
    info "Fetching $record_type records for $DOMAIN..."
    
    local response
    response=$(api_call "GET" "/v1/domains/$DOMAIN/records/$record_type")
    
    if echo "$response" | jq -e . >/dev/null 2>&1; then
        # Format output with printf instead of column command
        printf "%-20s %-40s %s\n" "NAME" "DATA" "TTL"
        echo "$response" | jq -r '.[] | "\(.name)\t\(.data)\t\(.ttl)"' | \
        while IFS=$'\t' read -r name data ttl; do
            printf "%-20s %-40s %s\n" "$name" "$data" "$ttl"
        done
        success "Retrieved $(echo "$response" | jq length) $record_type records"
    else
        error "Failed to fetch records: $response"
    fi
}

cmd_get() {
    local record_type="${1:-}"
    local record_name="${2:-}"
    
    if [[ -z "$record_type" ]] || [[ -z "$record_name" ]]; then
        error "Usage: $0 get <TYPE> <NAME>"
    fi
    
    info "Fetching $record_type record for $record_name.$DOMAIN..."
    
    local response
    response=$(api_call "GET" "/v1/domains/$DOMAIN/records/$record_type/$record_name")
    
    if echo "$response" | jq -e . >/dev/null 2>&1; then
        echo "$response" | jq '.'
    else
        error "Failed to fetch record: $response"
    fi
}

cmd_add() {
    local record_type="${1:-}"
    local record_name="${2:-}"
    local record_data="${3:-}"
    local ttl="${4:-3600}"
    
    if [[ -z "$record_type" ]] || [[ -z "$record_name" ]] || [[ -z "$record_data" ]]; then
        error "Usage: $0 add <TYPE> <NAME> <DATA> [TTL]"
    fi
    
    info "Adding $record_type record: $record_name.$DOMAIN -> $record_data (TTL: $ttl)"
    
    local json_data
    json_data=$(jq -n \
        --arg type "$record_type" \
        --arg name "$record_name" \
        --arg data "$record_data" \
        --argjson ttl "$ttl" \
        '[{type: $type, name: $name, data: $data, ttl: $ttl}]')
    
    local response
    response=$(api_call "PATCH" "/v1/domains/$DOMAIN/records" "$json_data")
    
    if [[ -z "$response" ]] || echo "$response" | jq -e . >/dev/null 2>&1; then
        success "Record added successfully"
    else
        error "Failed to add record: $response"
    fi
}

cmd_update() {
    local record_type="${1:-}"
    local record_name="${2:-}"
    local record_data="${3:-}"
    local ttl="${4:-3600}"
    
    if [[ -z "$record_type" ]] || [[ -z "$record_name" ]] || [[ -z "$record_data" ]]; then
        error "Usage: $0 update <TYPE> <NAME> <DATA> [TTL]"
    fi
    
    info "Updating $record_type record: $record_name.$DOMAIN -> $record_data (TTL: $ttl)"
    
    local json_data
    json_data=$(jq -n \
        --arg data "$record_data" \
        --argjson ttl "$ttl" \
        '[{data: $data, ttl: $ttl}]')
    
    local response
    response=$(api_call "PUT" "/v1/domains/$DOMAIN/records/$record_type/$record_name" "$json_data")
    
    if [[ -z "$response" ]] || echo "$response" | jq -e . >/dev/null 2>&1; then
        success "Record updated successfully"
    else
        error "Failed to update record: $response"
    fi
}

cmd_delete() {
    local record_type="${1:-}"
    local record_name="${2:-}"
    
    if [[ -z "$record_type" ]] || [[ -z "$record_name" ]]; then
        error "Usage: $0 delete <TYPE> <NAME>"
    fi
    
    warning "About to delete $record_type record: $record_name.$DOMAIN"
    read -r -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        info "Deletion cancelled"
        return 0
    fi
    
    local response
    response=$(api_call "DELETE" "/v1/domains/$DOMAIN/records/$record_type/$record_name")
    
    if [[ -z "$response" ]] || echo "$response" | jq -e . >/dev/null 2>&1; then
        success "Record deleted successfully"
    else
        error "Failed to delete record: $response"
    fi
}

cmd_export() {
    local output_file="${1:-$ZONE_FILE}"
    
    info "Exporting DNS records to $output_file..."
    
    local response
    response=$(api_call "GET" "/v1/domains/$DOMAIN/records")
    
    if ! echo "$response" | jq -e . >/dev/null 2>&1; then
        error "Failed to fetch records: $response"
    fi
    
    # Create zone file header
    cat > "$output_file" << EOF
; Domain: $DOMAIN
; Exported: $(date '+%Y-%m-%d %H:%M:%S')
; Environment: $API_ENV
;
; This file is intended for reference and backup purposes.
; Generated by godaddy-dns-manager.sh

\$ORIGIN ${DOMAIN}.

EOF
    
    # Export records by type
    for record_type in SOA A NS TXT CNAME MX SRV; do
        local records
        records=$(echo "$response" | jq -r ".[] | select(.type == \"$record_type\") | \"\(.name)\t\(.ttl)\t IN \t\(.type)\t\(.data)\"")
        
        if [[ -n "$records" ]]; then
            echo "; $record_type Records" >> "$output_file"
            echo "$records" >> "$output_file"
            echo "" >> "$output_file"
        fi
    done
    
    success "Zone file exported to $output_file"
}

cmd_compare() {
    local zone_file="${1:-$ZONE_FILE}"
    
    if [[ ! -f "$zone_file" ]]; then
        error "Zone file not found: $zone_file"
    fi
    
    info "Comparing $zone_file with live DNS records..."
    
    # Export current state to temp file
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT
    
    cmd_export "$temp_file" >/dev/null
    
    # Compare files
    if diff -u "$zone_file" "$temp_file" > /dev/null; then
        success "Zone file matches live DNS records"
    else
        warning "Differences found:"
        diff -u "$zone_file" "$temp_file" || true
    fi
}

cmd_help() {
    cat << EOF
GoDaddy DNS Manager for $DOMAIN

Usage: $0 <command> [arguments]

Commands:
  list                      List all DNS records
  list-type <TYPE>         List records of specific type (A, CNAME, TXT, etc.)
  get <TYPE> <NAME>        Get specific DNS record
  add <TYPE> <NAME> <DATA> [TTL]     Add new DNS record
  update <TYPE> <NAME> <DATA> [TTL]  Update existing DNS record
  delete <TYPE> <NAME>     Delete DNS record
  export [FILE]            Export all records to zone file (default: $ZONE_FILE)
  compare [FILE]           Compare zone file with live DNS
  help                     Show this help message

Environment Variables:
  GODADDY_API_KEY          GoDaddy API key (required)
  GODADDY_API_SECRET       GoDaddy API secret (required)
  GODADDY_API_ENV          API environment: OTE (test) or PRODUCTION (default: OTE)
  GODADDY_DOMAIN           Domain to manage (default: ism.la)

Examples:
  # List all records
  $0 list

  # List only CNAME records
  $0 list-type CNAME

  # Add a new CNAME record
  $0 add CNAME test crtrcooperator.duckdns.org

  # Update an existing A record
  $0 update A @ 192.168.1.100

  # Export current DNS to file
  $0 export

  # Compare local zone file with live DNS
  $0 compare

Current Configuration:
  Domain: $DOMAIN
  Environment: $API_ENV
  API Base: $API_BASE
  Zone File: $ZONE_FILE

EOF
}

# Main execution
main() {
    check_dependencies
    
    local command="${1:-help}"
    shift || true
    
    # Check credentials for all commands except help
    if [[ "$command" != "help" ]]; then
        check_credentials
    fi
    
    case "$command" in
        list)
            cmd_list "$@"
            ;;
        list-type)
            cmd_list_type "$@"
            ;;
        get)
            cmd_get "$@"
            ;;
        add)
            cmd_add "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        delete)
            cmd_delete "$@"
            ;;
        export)
            cmd_export "$@"
            ;;
        compare)
            cmd_compare "$@"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            error "Unknown command: $command. Use '$0 help' for usage information."
            ;;
    esac
}

main "$@"

