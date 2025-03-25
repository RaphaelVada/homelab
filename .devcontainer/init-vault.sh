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

# Prüfe ob wir im richtigen Verzeichnis sind
if [[ ! -f "docker-compose.yml" ]]; then
    error "Bitte führe das Script im Verzeichnis mit der docker-compose.yml aus"
fi

# Lade .env Datei
if [[ ! -f ".env" ]]; then
    error ".env Datei nicht gefunden"
fi

set -a
source .env
set +a

# Erstelle Verzeichnisstruktur
log "Erstelle Verzeichnisstruktur..."
mkdir -p ${VAULT_VOLUME_ROOT}/{config,certs,policies,file,logs}

# Erstelle Vault Konfiguration wenn sie nicht existiert
if [[ ! -f "${VAULT_VOLUME_ROOT}/config/vault.hcl" ]]; then
    log "Erstelle vault.hcl..."
    cat > "${VAULT_VOLUME_ROOT}/config/vault.hcl" << EOF
storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"

  telemetry {
    unauthenticated_metrics_access = false
  }
}

api_addr = "http://127.0.0.1:8200"
ui = true
disable_mlock = true

telemetry {
  disable_hostname = true
  prometheus_retention_time = "24h"
}

max_lease_ttl = "768h"    # 32 Tage
default_lease_ttl = "168h" # 7 Tage

audit_device "file" {
  path = "/vault/logs/audit.log"
}

# Single Key Setup
seal "shamir" {
  secret_shares = 1
  secret_threshold = 1
}
EOF
    success "vault.hcl erstellt"
fi

# Erstelle selbst-signiertes Zertifikat wenn es nicht existiert
if [[ ! -f "${VAULT_VOLUME_ROOT}/certs/vault.crt" ]]; then
    log "Erstelle selbst-signiertes Zertifikat..."
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout "${VAULT_VOLUME_ROOT}/certs/vault.key" \
        -out "${VAULT_VOLUME_ROOT}/certs/vault.crt" \
        -subj "/CN=vault/O=Homelab/C=DE" \
        -addext "subjectAltName = DNS:vault,DNS:localhost,IP:127.0.0.1"
    success "Zertifikate erstellt"
fi

# Setze Berechtigungen
# Setze Berechtigungen - Vault läuft als User 100:1000
#log "Setze Berechtigungen..."
#sudo chown -R 100:1000 "${VAULT_VOLUME_ROOT}"
#sudo chmod -R 750 "${VAULT_VOLUME_ROOT}"
#sudo chmod 600 "${VAULT_VOLUME_ROOT}/certs/vault.key"
#sudo chmod 644 "${VAULT_VOLUME_ROOT}/certs/vault.crt"
#sudo chmod 644 "${VAULT_VOLUME_ROOT}/config/vault.hcl"

success "Vault Initialisierung abgeschlossen!"
echo -e "\nNächste Schritte:"
echo "1. Überprüfe die Konfiguration in ${VAULT_VOLUME_ROOT}/config/vault.hcl"
echo "2. Führe 'docker compose up -d' aus um Vault zu starten"
echo "3. Initialisiere Vault mit 'docker exec -it bootstrap-vault vault operator init -key-shares=1 -key-threshold=1'"
echo "4. Bewahre die Unseal Keys und Root Token sicher auf"
