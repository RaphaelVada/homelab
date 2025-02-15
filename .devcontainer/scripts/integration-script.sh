# .devcontainer/scripts/initialize-env.sh
#!/bin/bash
set -e

# Konfiguration
export CONFIG_DIR="/workspace/live-config"
export DEVCONTAINER_DIR="/workspace/.devcontainer"
export PATH="$PATH:/usr/local/bin"

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging Funktionen
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Überprüfe Bitwarden CLI Installation
check_bw() {
    log "Checking Bitwarden CLI..."
    if ! command -v bw &> /dev/null; then
        log "Installing Bitwarden CLI..."
        npm install -g @bitwarden/cli
    fi
    success "Bitwarden CLI is available"
}

# Bitwarden Login
bw_login() {
    log "Setting up Bitwarden access..."
    
    # Prüfe bestehenden Login
    if ! bw login --check &> /dev/null; then
        warn "Please log in to Bitwarden"
        bw login
    fi
    
    # Unlock Vault
    if [ -z "$BW_SESSION" ]; then
        warn "Please unlock your Bitwarden vault"
        export BW_SESSION=$(bw unlock --raw)
        if [ $? -ne 0 ]; then
            error "Failed to unlock Bitwarden vault"
        fi
    fi
    
    success "Bitwarden vault unlocked"
}

# Hole Konfigurationen aus Bitwarden
fetch_configs() {
    log "Fetching configurations from Bitwarden..."
    
    # Erstelle Verzeichnisstruktur
    mkdir -p "$CONFIG_DIR"/{kubernetes,proxmox,talos,ansible}
    
    # Hole Configs basierend auf Bitwarden Labels
    bw list items --search homelab-config | jq -c '.[]' | while read -r item; do
        local name=$(echo "$item" | jq -r '.name')
        local content=$(echo "$item" | jq -r '.notes')
        local path=$(echo "$name" | sed 's/homelab-config-//')
        
        if [ ! -z "$content" ]; then
            echo "$content" > "$CONFIG_DIR/$path"
            success "Fetched: $path"
        fi
    done
}

# Speichere Konfigurationen in Bitwarden
save_configs() {
    log "Saving configurations to Bitwarden..."
    
    find "$CONFIG_DIR" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) | while read -r file; do
        local rel_path=${file#"$CONFIG_DIR/"}
        local item_name="homelab-config-$rel_path"
        local content=$(cat "$file")
        
        # Template für Bitwarden Item
        local template=$(jq -n \
            --arg name "$item_name" \
            --arg notes "$content" \
            '{
                "organizationId": null,
                "collectionIds": null,
                "folderId": null,
                "type": 2,
                "name": $name,
                "notes": $notes,
                "favorite": false,
                "secureNote": {
                    "type": 0
                }
            }')
        
        # Update oder Create
        if bw get item "$item_name" &> /dev/null; then
            bw edit item "$item_name" "$template" > /dev/null
            success "Updated: $rel_path"
        else
            bw create item "$template" > /dev/null
            success "Created: $rel_path"
        fi
    done
}

# Hauptfunktion
main() {
    case "$1" in
        "init")
            check_bw
            bw_login
            fetch_configs
            ;;
        "fetch")
            check_bw
            bw_login
            fetch_configs
            ;;
        "save")
            check_bw
            bw_login
            save_configs
            ;;
        *)
            echo "Usage: $0 {init|fetch|save}"
            exit 1
            ;;
    esac
}

main "$@"