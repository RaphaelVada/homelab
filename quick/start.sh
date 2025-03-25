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

    # Prüfe, ob NFS-Client installiert ist
    if ! command -v mount.nfs &> /dev/null; then
        error "NFS-Client scheint nicht installiert zu sein."
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

# NAS NFS Mount für Vault Volumes einrichten
setup_vault_volumes() {
    log "Richte NFS-Mount für Vault Volumes ein..."

    # NAS-Informationen abfragen
    echo ""
    echo "Bitte gib die IP-Adresse oder Hostnamen deines NAS ein:"
    read -p "NAS-Host > " NAS_HOST

    if [ -z "$NAS_HOST" ]; then
        error "NAS-Host darf nicht leer sein."
    fi

    echo ""
    echo "Bitte gib den NFS-Pfad auf dem NAS ein (z.B. /volume1/homelab/vault):"
    read -p "NFS-Pfad > " NAS_PATH

    if [ -z "$NAS_PATH" ]; then
        error "NFS-Pfad darf nicht leer sein."
    fi

    # Prüfe, ob der NAS erreichbar ist
    log "Prüfe, ob das NAS erreichbar ist..."
    if ping -c 1 $NAS_HOST &> /dev/null; then
        success "NAS ist erreichbar"
    else
        error "NAS ist nicht erreichbar. Stelle sicher, dass das NAS eingeschaltet ist und im Netzwerk erreichbar ist."
    fi

    # Vault Volumes Verzeichnispfad
    VAULT_VOLUMES_DIR="$PROJECT_DIR/_vault-volumes"

    # Erstelle Verzeichnis, falls es nicht existiert
    if [ ! -d "$VAULT_VOLUMES_DIR" ]; then
        mkdir -p "$VAULT_VOLUMES_DIR"
        log "Verzeichnis $VAULT_VOLUMES_DIR erstellt"
    fi

    # Versuche den NFS-Mount
    log "Versuche NFS-Mount von $NAS_HOST:$NAS_PATH nach $VAULT_VOLUMES_DIR..."
    if sudo mount -t nfs "$NAS_HOST:$NAS_PATH" "$VAULT_VOLUMES_DIR"; then
        success "NFS-Mount erfolgreich eingerichtet"

        # Prüfe, ob die erwarteten Verzeichnisse existieren
        if [ ! -d "$VAULT_VOLUMES_DIR/config" ] || [ ! -d "$VAULT_VOLUMES_DIR/certs" ] ||
           [ ! -d "$VAULT_VOLUMES_DIR/policies" ] || [ ! -d "$VAULT_VOLUMES_DIR/file" ] ||
           [ ! -d "$VAULT_VOLUMES_DIR/logs" ]; then
            warning "Die erwarteten Vault-Verzeichnisse wurden nicht im NFS-Mount gefunden."
            echo "Folgende Verzeichnisse müssen auf dem NAS unter $NAS_PATH existieren:"
            echo "- config"
            echo "- certs"
            echo "- policies"
            echo "- file"
            echo "- logs"

            # Löse den Mount wieder
            log "Löse NFS-Mount auf..."
            sudo umount "$VAULT_VOLUMES_DIR"

            error "Abbruch: Erforderliche Verzeichnisse fehlen. Bitte erstelle die Verzeichnisse auf dem NAS und versuche es erneut."
        fi

        # Speichere NFS-Mount Information
        log "NFS-Mount erfolgreich konfiguriert: $NAS_HOST:$NAS_PATH -> $VAULT_VOLUMES_DIR"

    else
        warning "NFS-Mount fehlgeschlagen. Mögliche Gründe:"
        echo "- NFS-Dienst ist auf dem NAS nicht aktiviert"
        echo "- NFS-Export für diesen Client ist nicht konfiguriert"
        echo "- Firewall blockiert NFS-Verbindungen"

        error "Abbruch: NFS-Mount konnte nicht hergestellt werden."
    fi

    success "Vault Volumes-Verzeichnis erfolgreich eingerichtet unter $VAULT_VOLUMES_DIR"
}

# Erstelle .env Datei
create_env_file() {
    log "Erstelle .env Datei..."

    ENV_FILE_PATH="$PROJECT_DIR/.devcontainer/.env"

    # Erstelle .devcontainer Verzeichnis, falls es nicht existiert
    if [ ! -d "$PROJECT_DIR/.devcontainer" ]; then
        error ".devcontainer Verzeichnis wurde erstenicht gefunden. Dies deutet darauf hin, dass das Repository möglicherweise nicht korrekt geklont wurde."
    fi

    # Setze VAULT_VOLUME_ROOT
    VAULT_VOLUME_ROOT="$VAULT_VOLUMES_DIR"

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
    echo "Vault Volumes (NFS-Mount): $VAULT_VOLUMES_DIR"
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
    echo -e "${YELLOW}NFS-Mount Information:${NC}"
    echo "Der NFS-Mount wird beim Neustart nicht automatisch wiederhergestellt."
    echo "Um den NFS-Mount nach einem Neustart manuell wiederherzustellen:"
    echo "sudo mount -t nfs $NAS_HOST:$NAS_PATH $VAULT_VOLUMES_DIR"
    echo ""
}

prepare(){
    # Führe alle Schritte aus
    check_prerequisites
    set_project_directory
    clone_repository
    setup_vault_volumes
    check_vault_configuration
    create_env_file
    build_docker_images
    show_completion_info
}

stop(){

}


# Hauptfunktion
main() {
    echo -e "${GREEN}=== Homelab Bootstrap Setup ===${NC}"
    prepare

}

# Führe Hauptfunktion aus
main
