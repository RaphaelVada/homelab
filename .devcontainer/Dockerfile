FROM ubuntu:24.04

# Vermeiden von interaktiven Dialogen während der Installation
ENV DEBIAN_FRONTEND=noninteractive

# Basis-Systempakete installieren
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    inotify-tools \
    curl \
    git \
    gnupg \
    jq \
    lsb-release \
    make \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    sshpass \
    unzip \
    wget \
    zsh \
    # Vault Installation
    #&& curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    #&& echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    #&& apt-get update \
    #&& apt-get install -y --no-install-recommends vault \
    # Zusätzliche Dependencies für Entwicklung
    && rm -rf /var/lib/apt/lists/*

#Download and install Vault binary directly
RUN curl -fsSL https://releases.hashicorp.com/vault/1.15.6/vault_1.15.6_linux_amd64.zip -o vault.zip \
    && unzip vault.zip \
    && mv vault /usr/local/bin/ \
    && rm vault.zip \
    && vault --version

# Python venv erstellen und aktivieren
RUN 
ENV PATH="/opt/venv/bin:$PATH"

# Python Tools in venv installieren
RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip3 install --no-cache-dir \
    ansible-core \
    proxmoxer \
    yq
ENV PATH="/opt/venv/bin:$PATH"

## Install only required Kubernetes tools
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl \
    && curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -sL https://talos.dev/install | sh


# Standard-Shell auf zsh setzen
RUN chsh -s /usr/bin/zsh root

# Post-Start Script kopieren und ausführbar machen
# Kopiere das gesamte scripts Verzeichnis
COPY ./scripts /usr/local/bin/

# Mache alle Skripte im Verzeichnis ausführbar 
RUN find /usr/local/bin -type f -name "*.sh" -exec chmod 755 {} + && \
    find /usr/local/bin -type f -name "*.sh" -exec chown root:root {} +

# Arbeitsverzeichnis setzen
WORKDIR /workspace

# Standard-Shell beim Container-Start
CMD [ "zsh" ]