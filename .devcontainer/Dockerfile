FROM ubuntu:24.04

# Vermeiden von interaktiven Dialogen während der Installation
ENV DEBIAN_FRONTEND=noninteractive

# Basis-Systempakete installieren
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    fzf \
    git \
    gnupg \
    graphviz \
    jq \
    lsb-release \
    make \
    openssh-client \
    plantuml \
    python3-full \
    python3-pip \
    python3-venv \
    sshpass \
    unzip \
    vim \
    wget \
    zsh \
    # Zusätzliche Dependencies für Entwicklung
    build-essential \
    default-jre \
    && rm -rf /var/lib/apt/lists/*

# Python venv erstellen und aktivieren
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python Tools in venv installieren
RUN . /opt/venv/bin/activate && \
    pip3 install --no-cache-dir \
    ansible \
    proxmoxer \
    yamllint \
    yq

# kubectl installieren
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Helm installieren
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Talosctl installieren
RUN curl -sL https://talos.dev/install | sh

# k9s installieren
RUN K9S_VERSION=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') \
    && curl -L "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | tar xz -C /usr/local/bin

# Kustomize installieren
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/

# Go installieren (für mögliche Go Entwicklung)
RUN GO_VERSION="1.22.0" \
    && curl -L "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xzf -
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/workspace/go
ENV PATH=$PATH:$GOPATH/bin

# Oh My Zsh installieren
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Oh My Zsh Plugins und Theme
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Zsh Konfiguration
RUN echo 'export ZSH="/root/.oh-my-zsh"\n\
ZSH_THEME="robbyrussell"\n\
plugins=(git kubectl helm ansible docker zsh-autosuggestions zsh-syntax-highlighting)\n\
source $ZSH/oh-my-zsh.sh\n\
\n\
# Python venv aktivieren\n\
source /opt/venv/bin/activate\n\
\n\
# Kubernetes Aliases\n\
alias k="kubectl"\n\
alias kns="kubectl config set-context --current --namespace"\n\
alias kctx="kubectl config use-context"\n\
\n\
# Talos Aliases\n\
alias tc="talosctl"\n\
\n\
# Helm Aliases\n\
alias h="helm"\n\
\n\
# Ansible Aliases\n\
alias ap="ansible-playbook"\n\
\n\
# Go Path\n\
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin\n\
' > /root/.zshrc

# Standard-Shell auf zsh setzen
RUN chsh -s /usr/bin/zsh root

# Arbeitsverzeichnis setzen
WORKDIR /workspace

# Standard-Shell beim Container-Start
CMD [ "zsh" ]