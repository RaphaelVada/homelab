#!/bin/bash
set -e

# Farben für Ausgaben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging Funktionen
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Voraussetzungen prüfen
check_prerequisites() {
    log "Prüfe Voraussetzungen..."

    # Prüfe, ob Git installiert ist
    if ! command -v git &> /dev/null; then
        error "Git ist nicht installiert. Bitte installiere Git und versuche es erneut."
    fi

    # Prüfe, ob Docker installiert ist
    if ! command -v docker &> /dev/null; then
        error "Docker ist nicht installiert. Bitte installiere Docker und versuche es erneut."
    fi

    # Prüfe, ob Docker Compose installiert ist
    if ! command -v docker compose &> /dev/null; then
        warning "Docker Compose V2 nicht gefunden. Prüfe auf ältere Version..."
        if ! command -v docker-compose &> /dev/null; then
            error "Docker Compose ist nicht installiert. Bitte installiere Docker Compose und versuche es erneut."
        fi
    fi

    success "Alle Voraussetzungen erfüllt!"
}

# Projektverzeichnis festlegen
set_project_directory() {
    echo ""
    echo "Bitte gib den absoluten Pfad für das Projektverzeichnis an"
    echo "(oder drücke Enter für das aktuelle Verzeichnis):"
    read -p "> " PROJECT_DIR

    # Wenn keine Eingabe, verwende aktuelles Verzeichnis
    if [ -z "$PROJECT_DIR" ]; then
        PROJECT_DIR=$(pwd)
    fi

    # Prüfe, ob das Verzeichnis existiert
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "Verzeichnis $PROJECT_DIR existiert nicht. Soll es erstellt werden? (j/n)"
        read -p "> " CREATE_DIR
        if [[ "$CREATE_DIR" =~ ^[jJ] ]]; then
            mkdir -p "$PROJECT_DIR"
        else
            error "Verzeichnis existiert nicht und soll nicht erstellt werden. Abbruch."
        fi
    fi

    # Absoluten Pfad ermitteln
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

    log "Projektverzeichnis: $PROJECT_DIR"
}

# Repository klonen
clone_repository() {
    log "Klone Repository..."

    # Repository URL
    REPO_URL="https://github.com/RaphaelVada/homelab.git"

    # Prüfe, ob das Verzeichnis bereits existiert und nicht leer ist
    if [ -d "$PROJECT_DIR" ] && [ "$(ls -A $PROJECT_DIR)" ]; then
        error "Das Verzeichnis $PROJECT_DIR ist nicht leer."
    fi

    # Repository klonen
    cd "$PROJECT_DIR"
    if git clone "$REPO_URL" .; then
        success "Repository erfolgreich geklont"
    else
        error "Fehler beim Klonen des Repositories"
    fi
}

# Erstelle .env Datei
create_env_file() {
    log "Erstelle .env Datei..."

    ENV_FILE_PATH="$PROJECT_DIR/.devcontainer/.env"

    # Erstelle .devcontainer Verzeichnis, falls es nicht existiert
    if [ ! -d "$PROJECT_DIR/.devcontainer" ]; then
        error ".devcontainer Verzeichnis wurde nicht gefunden. Dies deutet darauf hin, dass das Repository möglicherweise nicht korrekt geklont wurde."
    fi

    # Frage nach NFS_ADRESS
    echo ""
    echo "Bitte gib die IP-Adresse oder den Hostnamen deines NAS ein:"
    read -p "NFS_ADRESS > " NFS_ADRESS

    if [ -z "$NFS_ADRESS" ]; then
        error "NFS_ADRESS darf nicht leer sein."
    fi

    # Frage nach VAULT_VOLUME_ROOT
    echo ""
    echo "Bitte gib den Pfad zum Vault Volume auf dem NAS ein:"
    echo "Beispiel: /volume1/bootstrap/vault-volume"
    read -p "VAULT_VOLUME_ROOT > " VAULT_VOLUME_ROOT

    if [ -z "$VAULT_VOLUME_ROOT" ]; then
        error "VAULT_VOLUME_ROOT darf nicht leer sein."
    fi

    # Frage nach VAULT_TOKEN und VAULT_UNSEAL_KEY
    echo ""
    echo "Bitte gib den Vault Token ein (falls nicht vorhanden, wird ein neuer generiert):"
    read -p "VAULT_TOKEN > " VAULT_TOKEN

    echo ""
    echo "Bitte gib den Vault Unseal Key ein (falls nicht vorhanden, wird ein neuer generiert):"
    read -p "VAULT_UNSEAL_KEY > " VAULT_UNSEAL_KEY

    # Erstelle .env Datei
    cat > "$ENV_FILE_PATH" << EOF
# Generiert durch das Bootstrap-Script am $(date)
VAULT_VOLUME_ROOT=$VAULT_VOLUME_ROOT
NFS_ADRESS=$NFS_ADRESS
VAULT_TOKEN=$VAULT_TOKEN
VAULT_UNSEAL_KEY=$VAULT_UNSEAL_KEY
EOF

    success ".env Datei erfolgreich erstellt unter $ENV_FILE_PATH"

    # Hinweis auf Sicherheit
    echo ""
    echo -e "${YELLOW}Wichtig: Die Zugangsdaten wurden in der .env Datei gespeichert.${NC}"
    echo "Diese Datei enthält sensitive Informationen und sollte sicher aufbewahrt werden."
    echo ""
}

# Baue Docker Images für die Entwicklungsumgebung
build_docker_images() {
    log "Baue Docker Images für die Entwicklungsumgebung..."

    cd "$PROJECT_DIR/.devcontainer"

    # Setze Docker Compose Befehl basierend auf vorhandener Version
    if command -v docker compose &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    else
        DOCKER_COMPOSE="docker-compose"
    fi

    # Baue Docker Images ohne sie zu starten
    log "Baue Docker Images - Dies kann einige Minuten dauern..."
    $DOCKER_COMPOSE build

    if [ $? -ne 0 ]; then
        error "Fehler beim Bauen der Docker Images. Bitte überprüfe die Logs."
    else
        success "Docker Images erfolgreich gebaut!"
    fi
}

# Zeige abschließende Informationen
show_completion_info() {
    echo ""
    echo -e "${GREEN}=== Bootstrap erfolgreich abgeschlossen ===${NC}"
    echo ""
    echo "Projektverzeichnis: $PROJECT_DIR"
    echo "NAS Adresse: $NFS_ADRESS"
    echo "Vault Volume Root auf NAS: $VAULT_VOLUME_ROOT"
    echo ""
    echo -e "${YELLOW}Wichtige nächste Schritte:${NC}"
    echo "1. Öffne das Projektverzeichnis in VS Code: code $PROJECT_DIR"
    echo "2. Starte die Container manuell mit: cd $PROJECT_DIR/.devcontainer && docker compose up -d"
    echo "3. Oder verwende den 'Remote Containers: Reopen in Container' Befehl in VS Code"
    echo "   um die Entwicklungsumgebung zu starten."
    echo ""
    echo -e "${YELLOW}Vault UI:${NC}"
    echo "Nach dem Start ist die Vault UI erreichbar unter https://localhost:8200"
    echo "Die Zugangsdaten befinden sich in der .env Datei unter .devcontainer/.env"
    echo ""
    echo -e "${YELLOW}Wichtiger Hinweis:${NC}"
    echo "Stelle sicher, dass das angegebene Vault-Volume-Verzeichnis auf dem NAS existiert"
    echo "und alle benötigten Unterverzeichnisse enthält (/config, /certs, /policies, /file, /logs)."
    echo ""
}

# Hauptfunktion
main() {
    echo -e "${GREEN}=== Homelab Bootstrap Setup ===${NC}"
    
    # Führe alle Schritte aus
    check_prerequisites
    set_project_directory
    clone_repository
    create_env_file
    build_docker_images
    show_completion_info
}

# Führe Hauptfunktion aus
main