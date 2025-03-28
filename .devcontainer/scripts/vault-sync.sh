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

# Konfiguration
SECRETS_DIR="/secrets"          # Basis-Verzeichnis für Secrets
VAULT_BASE_PATH="secret/"       # Basis-Pfad im Vault
SYNC_LOG="/var/log/vault-sync.log"


# Prüft ob Vault erreichbar und entsperrt ist
check_vault() {
    if ! vault status >/dev/null 2>&1; then
        error "Vault nicht erreichbar"
        return 1
    fi
    if vault status | grep -q "Sealed.*true"; then
        error "Vault ist sealed"
        return 1
    fi
    return 0
}

# Konvertiert Dateipfad zu Vault-Pfad
to_vault_path() {
    local file_path="$1"
    echo "$VAULT_BASE_PATH${file_path#$SECRETS_DIR/}"
}

# Konvertiert Vault-Pfad zu Dateipfad
to_file_path() {
    local vault_path="$1"
    echo "$SECRETS_DIR/${vault_path#$VAULT_BASE_PATH}"
}

# Lädt ein Secret aus dem Vault
download_secret() {
    local vault_path="$1"
    local file_path="$(to_file_path "$vault_path")"
    local dir_path="$(dirname "$file_path")"
    
    mkdir -p "$dir_path"
    if vault kv get -field=value "$vault_path" > "$file_path" 2>/dev/null; then
        log "Downloaded: $vault_path -> $file_path"
        return 0
    else
        error "Failed to download: $vault_path"
        return 1
    fi
}

# Lädt ein Secret in den Vault
upload_secret() {
    local file_path="$1"
    local vault_path="$(to_vault_path "$file_path")"
    
    if vault kv put "$vault_path" value="@$file_path" >/dev/null; then
        success "Uploaded: $file_path -> $vault_path"
        return 0
    else
        error "Failed to upload: $file_path"
        return 1
    fi
}

# Synct alle Dateien zum Vault
sync_to_vault() {
    log "Starting sync to vault..."
    find "$SECRETS_DIR" -type f -print0 | while IFS= read -r -d '' file; do
        upload_secret "$file"
    done
}

# Synct alle Secrets aus dem Vault
sync_from_vault() {
    log "Starting sync from vault..."
    vault kv list -format=json "$VAULT_BASE_PATH" | jq -r '.[]' | while read -r path; do
        download_secret "$VAULT_BASE_PATH$path"
    done
}

# Überwacht Änderungen im Verzeichnis und synct automatisch
watch_and_sync() {
    log "Starting file watch mode..."
    while true; do
        inotifywait -r -e modify,create,delete "$SECRETS_DIR"
        sleep 1  # Kleine Pause für Batch-Änderungen
        sync_to_vault
    done
}

# Hauptfunktion
main() {
    case "$1" in
        "to-vault")
            check_vault && sync_to_vault
            ;;
        "from-vault")
            check_vault && sync_from_vault
            ;;
        "watch")
            check_vault && watch_and_sync
            ;;
        *)
            echo "Usage: $0 {to-vault|from-vault|watch}"
            echo "  to-vault    : Synct lokale Dateien zum Vault"
            echo "  from-vault  : Synct Vault-Secrets zu lokalen Dateien"
            echo "  watch      : Überwacht Änderungen und synct automatisch"
            exit 1
            ;;
    esac
}

main "$@"
