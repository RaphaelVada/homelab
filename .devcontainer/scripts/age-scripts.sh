#!/bin/bash
# decrypt-configs.sh
set -e

AGE_KEY_FILE="${AGE_KEY_FILE:-$HOME/.age/key.txt}"
CONFIG_DIR="${CONFIG_DIR:-/workspace/live-config}"
ENCRYPTED_DIR="${ENCRYPTED_DIR:-/mnt/nas/homelab-config}"

# Überprüfe ob age installiert ist
if ! command -v age &> /dev/null; then
    echo "Installing age..."
    curl -Lo age.tar.gz https://github.com/FiloSottile/age/releases/latest/download/age-v1.1.1-linux-amd64.tar.gz
    tar xf age.tar.gz
    mv age/age /usr/local/bin/
    mv age/age-keygen /usr/local/bin/
    rm -rf age age.tar.gz
fi

# Erstelle Schlüssel wenn nicht vorhanden
if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "Generating new age key..."
    mkdir -p "$(dirname "$AGE_KEY_FILE")"
    age-keygen -o "$AGE_KEY_FILE"
fi

# Entschlüssele Konfigurationen
echo "Decrypting configurations..."
mkdir -p "$CONFIG_DIR"
for encrypted_file in "$ENCRYPTED_DIR"/*.age; do
    if [ -f "$encrypted_file" ]; then
        filename=$(basename "$encrypted_file" .age)
        echo "Decrypting $filename..."
        age -d -i "$AGE_KEY_FILE" "$encrypted_file" > "$CONFIG_DIR/$filename"
    fi
done

echo "Configuration decryption complete!"

---
#!/bin/bash
# encrypt-configs.sh
set -e

AGE_KEY_FILE="${AGE_KEY_FILE:-$HOME/.age/key.txt}"
CONFIG_DIR="${CONFIG_DIR:-/workspace/live-config}"
ENCRYPTED_DIR="${ENCRYPTED_DIR:-/mnt/nas/homelab-config}"

# Extrahiere den public key
PUBLIC_KEY=$(age-keygen -y "$AGE_KEY_FILE")

# Verschlüssele Konfigurationen
echo "Encrypting configurations..."
mkdir -p "$ENCRYPTED_DIR"
for config_file in "$CONFIG_DIR"/*; do
    if [ -f "$config_file" ]; then
        filename=$(basename "$config_file")
        echo "Encrypting $filename..."
        age -R <(echo "$PUBLIC_KEY") -o "$ENCRYPTED_DIR/$filename.age" "$config_file"
    fi
done

echo "Configuration encryption complete!"