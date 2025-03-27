#!/bin/bash
set -euo pipefail

# Farben für Ausgaben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} Lade Secrets..."
vault-sync.sh from-vault
# Symlinks werden hier hinzugefügt


chmod 600 /secrets/ssh_bootstrap-ssh
chmod 600 /secrets/ssh_bootstrap-ssh.pub

ln -s /secrets/ssh_bootstrap-ssh /root/.ssh/id_ed25519
ln -s /secrets/ssh_bootstrap-ssh.pub /root/.ssh/id_ed25519.pub

ln -s /secrets/services_core-dns_Corefile /workspace/services/core-dns/Corefile
ln -s /secrets/ervices_core-dns_internal-domain.db /workspace/services/core-dns/internal-domain.db

chmod 600 /root/.ssh/id_ed25519
chmod 600 /root/.ssh/id_ed25519.pub

ln -s /secrets/services_core-dns_Corefile /workspace/services/core-dns/Corefile
ln -s /secrets/ervices_core-dns_internal-domain.db /workspace/services/core-dns/internal-domain.db

ln -sf "/secrets/workspace_.devcontainer_scripts_testfile.txt" "/workspace/.devcontainer/scripts/testfile.txt"
echo -e "${GREEN}[SUCCESS]${NC} Secrets geladen."
