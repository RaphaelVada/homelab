FROM ubuntu:24.04

# Vermeiden von interaktiven Dialogen während der Installation
ENV DEBIAN_FRONTEND=noninteractive

# Basis-Systempakete installieren
RUN apt-get update && \
    apt install software-properties-common -y --no-install-recommends && \
    add-apt-repository --yes --update ppa:ansible/ansible && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    inotify-tools \
    vim \
    curl \
    git \
    gnupg \
    jq \
    dnsutils \
    lsb-release \
    make \
    iputils-ping \
    iproute2 \
    net-tools \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    sshpass \
    rsync \
    unzip \
    wget \
    zsh \
    ansible \
    ansible-lint \
    locales \
    && locale-gen de_DE.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8
ENV LANGUAGE=de_DE.UTF-8

# Python Tools in venv installieren
RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip3 install --no-cache-dir \
    ansible-core \
    proxmoxer \
    docker \
    yq
ENV PATH="/opt/venv/bin:$PATH"

RUN ansible-galaxy collection install community.docker
#Download and install Vault binary directly
RUN curl -fsSL https://releases.hashicorp.com/vault/1.15.6/vault_1.15.6_linux_amd64.zip -o vault.zip \
    && unzip vault.zip \
    && mv vault /usr/local/bin/ \
    && rm vault.zip \
    && vault --version

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
