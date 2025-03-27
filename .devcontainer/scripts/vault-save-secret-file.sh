#!/bin/bash
###############################################################################
# Secret-Link - Tool zum Verwalten von Secrets im Homelab-Infrastruktur-Projekt
#
# Dieses Skript verschiebt eine Datei ins /secrets Verzeichnis, erstellt einen
# Symlink an der ursprünglichen Position und fügt entsprechende Einträge zur
# .gitignore und load-secrets.sh hinzu.
#
# Verwendung: ./secret-link.sh <dateipfad>
###############################################################################
set -euo pipefail

# Farbdefinitionen für die Ausgabe
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Hilfsfunktionen für die Ausgabe
# -----------------------------------------------------------------------------

# Gibt eine Info-Nachricht aus
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Gibt eine Erfolgsmeldung aus
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Gibt eine Fehlermeldung aus und beendet das Skript
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# -----------------------------------------------------------------------------
# Pfad-Verarbeitungsfunktionen
# -----------------------------------------------------------------------------

# Konvertiert einen relativen oder absoluten Pfad in einen vollständigen absoluten Pfad
# $1: Ein Dateipfad (relativ oder absolut)
# Gibt den normalisierten absoluten Pfad zurück
normalize_path() {
    local path="$1"
    local absolute_path

    # Prüfen, ob der Pfad bereits absolut ist
    if [[ "$path" == /* ]]; then
        absolute_path="$path"
    else
        # Relativer Pfad - konvertiere zu absolut bezogen auf aktuelles Verzeichnis
        # Entferne zuerst ein eventuelles ./ am Anfang
        absolute_path="$(pwd)/${path#./}"
    fi

    # Normalisiere den Pfad (löst . und .. auf)
    echo "$(cd "$(dirname "$absolute_path")" 2>/dev/null && pwd)/$(basename "$absolute_path")"
}

# Konvertiert einen Dateipfad in einen flachen Secret-Pfad für das /secrets Verzeichnis
# $1: Ein normalisierter Dateipfad
# Gibt den transformierten Secret-Pfad zurück (Verzeichnisstruktur mit _ statt /)
to_secret_path() {
    local file_path="$1"

    # Entferne führende / falls vorhanden (für die Konversion)
    file_path="${file_path#/}"

    # Extrahiere Dateiname und Verzeichnispfad
    local dir_path=$(dirname "$file_path")
    local file_name=$(basename "$file_path")

    # Ersetze / durch _ im Verzeichnispfad
    local secret_dir_path="${dir_path//\//_}"

    # Wenn kein Verzeichnis (also nur Dateiname), dann kein Unterstrich hinzufügen
    if [ "$dir_path" = "." ]; then
        echo "$file_name"
    else
        echo "${secret_dir_path}_${file_name}"
    fi
}

# -----------------------------------------------------------------------------
# Prüfungsfunktionen
# -----------------------------------------------------------------------------

# Prüft, ob die angegebene Datei existiert
# $1: Dateipfad
check_file() {
    local file_path="$1"
    if [ ! -f "$file_path" ]; then
        error "Datei '$file_path' existiert nicht."
    fi
}

# Prüft, ob eine Datei bereits in .gitignore eingetragen ist
# $1: Dateipfad (relativ zu /workspace)
# Rückgabewert: 0 (true) wenn bereits vorhanden, 1 (false) wenn nicht
is_in_gitignore() {
    local file_path="$1"

    # Entferne führende ./ oder / falls vorhanden für den Vergleich
    file_path="${file_path#./}"
    file_path="${file_path#/}"

    if grep -q "^$file_path$" "/workspace/.gitignore" 2>/dev/null; then
        return 0 # True, ist bereits in .gitignore
    else
        return 1 # False, nicht in .gitignore
    fi
}

# -----------------------------------------------------------------------------
# Aktionsfunktionen
# -----------------------------------------------------------------------------

# Fügt einen Dateipfad zur .gitignore-Datei hinzu
# $1: Originaler Dateipfad
add_to_gitignore() {
    local original_path="$1"

    # Bestimme den relativen Pfad für .gitignore (relativ zu /workspace)
    local workspace_relative_path
    if [[ "$original_path" == /workspace/* ]]; then
        # Wenn der Pfad bereits mit /workspace/ beginnt, entferne diesen Teil
        workspace_relative_path="${original_path#/workspace/}"
    else
        # Andernfalls versuche, einen relativen Pfad zu erstellen
        workspace_relative_path=$(realpath --relative-to=/workspace "$original_path" 2>/dev/null || echo "$original_path")
    fi

    # Füge Datei zu .gitignore hinzu, wenn sie noch nicht drin ist
    if ! is_in_gitignore "$workspace_relative_path"; then
        log "Füge '$workspace_relative_path' zu .gitignore hinzu"
        echo "$workspace_relative_path" >> "/workspace/.gitignore"
        success "Zu .gitignore hinzugefügt"
    else
        log "Datei '$workspace_relative_path' bereits in .gitignore"
    fi
}

# Fügt einen Symlink-Befehl zur load-secrets.sh hinzu
# $1: Originaler Dateipfad
# $2: Secret-Pfad (ohne /secrets/ Präfix)
add_to_load_secrets() {
    local original_path="$1"
    local secret_path="$2"
    local script_path="/workspace/.devcontainer/scripts/load-secrets.sh"

    # Prüfe, ob die load-secrets.sh existiert
    if [ ! -f "$script_path" ]; then
        error "Die Datei '$script_path' existiert nicht. Bitte erstelle sie manuell."
    fi

    # Erzeuge den Befehl zum Erstellen des Symlinks
    # Wir verwenden den original_path, da dieser der korrekte absolute Zielpfad ist
    local symlink_cmd="ln -sf \"/secrets/$secret_path\" \"$original_path\""

    # Überprüfe, ob der Befehl bereits in der Datei vorhanden ist
    if grep -q "$symlink_cmd" "$script_path"; then
        log "Symlink-Befehl für '$original_path' bereits in load-secrets.sh vorhanden"
    else
        # Füge den Befehl vor der letzten Zeile ein (der Erfolgsmeldung)
        sed -i "/echo -e \"\${GREEN}\[SUCCESS\]/i $symlink_cmd" "$script_path"
        success "Symlink-Befehl zu load-secrets.sh hinzugefügt"
    fi
}

# -----------------------------------------------------------------------------
# Hauptfunktion
# -----------------------------------------------------------------------------

main() {
    # Prüfe, ob ein Argument übergeben wurde
    if [ $# -lt 1 ]; then
        error "Verwendung: $0 <dateipfad>"
    fi

    # Normalisiere den Eingabepfad zu einem absoluten Pfad
    local input_path="$1"
    local original_path=$(normalize_path "$input_path")

    log "Normalisierter Pfad: $original_path"

    # Prüfe, ob die Datei existiert
    check_file "$original_path"

    # Erzeuge Secret-Pfad für die Datei
    local secret_path=$(to_secret_path "$original_path")
    log "Secret-Pfad: /secrets/$secret_path"

    # Verschiebe Datei nach /secrets
    log "Verschiebe '$original_path' nach '/secrets/$secret_path'"
    mv "$original_path" "/secrets/$secret_path"
    success "Datei nach /secrets verschoben"

    # Füge Datei zu .gitignore hinzu
    add_to_gitignore "$original_path"

    # Erstelle Symlink von der Secret-Datei zum Originalpfad
    log "Erstelle Symlink von '/secrets/$secret_path' zu '$original_path'"
    ln -sf "/secrets/$secret_path" "$original_path"
    success "Symlink erstellt"

    # Füge Symlink-Befehl zu load-secrets.sh hinzu
    add_to_load_secrets "$original_path" "$secret_path"

    # Abschlussmeldung
    success "Datei '$original_path' wurde erfolgreich als Secret eingerichtet"
    log "Beim Container-Start wird der Symlink automatisch erstellt"
    log "Sichere Secrets in den Vault"
    vault-sync.sh to-vault
}

# Starte Hauptfunktion mit allen übergebenen Argumenten
main "$@"
