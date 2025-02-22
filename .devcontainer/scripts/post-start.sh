#!/bin/bash
set -euo pipefail

# Farben für Ausgaben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging Funktion
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Prüfe ob VAULT_TOKEN gesetzt ist
if [ -z "${VAULT_TOKEN:-}" ]; then
    error "VAULT_TOKEN ist nicht gesetzt"
fi

# Warte auf Vault und unseal
log "Warte auf Vault und führe Unseal durch..."
until vault operator unseal $VAULT_TOKEN > /dev/null 2>&1; do
    sleep 1
done
success "Vault ist entsperrt"

# Aktiviere KV secrets engine
log "Aktiviere KV Secrets Engine..."
vault secrets enable -path=secret kv-v2 || true
success "KV Secrets Engine aktiviert"

success "Vault Initialisierung abgeschlossen!"
echo ""
echo "Verfügbare Secrets:"
vault kv list secret/