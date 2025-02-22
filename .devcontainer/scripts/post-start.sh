#!/bin/bash
set -euo pipefail

# Farben für Ausgaben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging Funktionen
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

# Prüfe notwendige Umgebungsvariablen
if [ -z "${VAULT_UNSEAL_KEY:-}" ]; then
    error "VAULT_UNSEAL_KEY ist nicht gesetzt"
fi

if [ -z "${VAULT_TOKEN:-}" ]; then
    error "VAULT_TOKEN ist nicht gesetzt"
fi

# Warte auf Vault Service
log "Warte auf Vault Service..."
until curl -k -fs https://vault:8200/v1/sys/health > /dev/null 2>&1 || curl -k -fs https://vault:8200/v1/sys/seal-status > /dev/null 2>&1; do
    log "Vault noch nicht erreichbar, warte..."
    sleep 2
done

# Prüfe Seal Status
seal_status=$(curl -fs -k https://vault:8200/v1/sys/seal-status | jq -r .sealed)
if [ "$seal_status" = "true" ]; then
    log "Vault ist versiegelt. Führe Unseal durch..."
    # Unseal durchführen
    vault operator unseal $VAULT_UNSEAL_KEY > /dev/null 2>&1
    success "Vault erfolgreich entsperrt"
else
    log "Vault ist bereits entsperrt"
fi

# Authentifizierung zurücksetzen und neu durchführen
log "Führe Vault Login durch..."
vault login "$VAULT_TOKEN" > /dev/null 2>&1
success "Vault Login erfolgreich"

# Aktiviere KV secrets engine, falls noch nicht geschehen
if ! vault secrets list | grep -q "^secret/"; then
    log "Aktiviere KV Secrets Engine..."
    vault secrets enable -path=secret kv-v2 || true
    success "KV Secrets Engine aktiviert"
fi

# Setze Token wieder als Umgebungsvariable
export VAULT_TOKEN="$VAULT_TOKEN"

success "Vault Initialisierung abgeschlossen!"