#!/bin/bash
# post-create.sh - Wird nach der Container-Erstellung ausgeführt

set -e

# Oh-my-zsh Plugins installieren
echo "Installing Oh My Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Basis .zshrc erstellen
echo "Configuring Zsh..."
cat > ~/.zshrc << 'EOL'
# Oh My Zsh Konfiguration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
  git
  docker
  kubectl
  helm
  ansible
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Umgebungsvariablen
export KUBECONFIG="$HOME/live-config/kubernetes/kubeconfig"
export TALOSCONFIG="$HOME/live-config/talos/config"

# Aliase
alias k=kubectl
alias tc=talosctl
alias h=helm
alias kns=kubens
alias kctx=kubectx
alias px="proxmox-api-cli"

# Kubernetes Completion
source <(kubectl completion zsh)
source <(helm completion zsh)
source <(talosctl completion zsh)

# Pfade
export PATH="$PATH:$HOME/.local/bin"

EOL

# Erstelle live-config Struktur wenn nicht vorhanden
echo "Setting up live-config directory structure..."
mkdir -p ~/live-config/{kubernetes,talos,proxmox,ansible}

echo "Shell setup complete!"