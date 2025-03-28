Hier ist die Zusammenfassung unserer SOPS/AGE-Verschlüsselungslösung für Git:

Voraussetzungen installieren (auf Mint):

bashCopysudo apt-get install age
curl -Lo sops https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64
chmod +x sops
sudo mv sops /usr/local/bin/

AGE-Key generieren und auslesen:

bashCopy# Key generieren
mkdir -p ~/.age
age-keygen -o ~/.age/key.txt

# Key für späteren Gebrauch in Variable speichern

AGE_PUBLIC_KEY=$(grep "public key:" ~/.age/key.txt | cut -d: -f2 | tr -d ' ')

# SOPS-Umgebungsvariable setzen

export SOPS_AGE_KEY_FILE=~/.age/key.txt

Git-Repository einrichten:

bashCopy# Repository initialisieren (ohne --bare für bessere Sichtbarkeit)
git init /pfad/zum/repo

# SOPS-Konfiguration erstellen

cat > /pfad/zum/repo/.sops.yaml << EOF
creation_rules:

- encrypted_regex: '^(.+)$'
    age: "${AGE_PUBLIC_KEY}"
  EOF

# .gitattributes erstellen (alle Dateien außer Konfiguration verschlüsseln)

cat > /pfad/zum/repo/.gitattributes << EOF

- filter=sops diff=sops merge=sops binary
  .gitattributes !filter
  .sops.yaml !filter
  EOF

# Konfigurationsdateien einchecken

git -C /pfad/zum/repo add .sops.yaml .gitattributes
git -C /pfad/zum/repo commit -m "Add SOPS configuration"

Git-Filter für automatische Ver-/Entschlüsselung einrichten:

bashCopygit -C /pfad/zum/repo config --local filter.sops.clean 'sops --encrypt --age ${AGE_PUBLIC_KEY} /dev/stdin'
git -C /pfad/zum/repo config --local filter.sops.smudge 'sops --decrypt /dev/stdin'

Neues Arbeitsverzeichnis klonen und einrichten:

bashCopy# Repository klonen
git clone /pfad/zum/quell/repo /pfad/zum/arbeitsverzeichnis

# Filter im neuen Repo konfigurieren

git -C /pfad/zum/arbeitsverzeichnis config --local filter.sops.clean 'sops --encrypt --age ${AGE_PUBLIC_KEY} /dev/stdin'
git -C /pfad/zum/arbeitsverzeichnis config --local filter.sops.smudge 'sops --decrypt /dev/stdin'
Mit dieser Konfiguration:

Werden alle neuen Dateien (außer .gitattributes und .sops.yaml) automatisch verschlüsselt
Sind Dateien im Arbeitsverzeichnis automatisch entschlüsselt
Werden Dateien im Repository verschlüsselt gespeichert
Funktioniert die normale Git-Workflow (add, commit, push, pull)

Wichtige Anmerkungen:

Der SOPS_AGE_KEY_FILE muss in jeder Shell gesetzt sein, in der gearbeitet wird
Der Age-Private-Key muss sicher aufbewahrt werden
.gitattributes und .sops.yaml müssen unverschlüsselt bleiben
Binärdateien werden auch verschlüsselt, aber möglicherweise mit Performance-Einbußen
