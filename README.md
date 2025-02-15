# Homelab

This is the repository of my private homelab setup. Feel free to take a look around.

## Anforderungen

### Infrastruktur
- Proxmox als VirtualisiAerungsplattform
- Mehrere Thin Clients als Hardware
- NAS für persistenten Speicher
- Kubernetes als Container-Orchestrierung
- Talos OS als spezialisiertes Kubernetes-Betriebssystem

### Workloads
- Paperless-ng
- PostgreSQL Datenbanken
- Teddycloud
- Nextcloud
- MinIO
- Eigenentwickelte Python und Go Anwendungen

## Ziele

### Reproduzierbarkeit
- Vollständig automatisierte Setup-Prozesse
- Infrastructure as Code für alle Komponenten
- Versionierte Konfigurationen
- Dokumentierte Prozesse

### Wartbarkeit
- Zentrale Verwaltung aller Konfigurationen
- Automatisierte Updates
- Standardisierte Backup-Prozesse
- Monitoring und Alerting

### Entwicklungsumgebung
- Containerisierte Entwicklungsumgebung
- Vollständige Tool-Suite
- Integrierte Dokumentations-Werkzeuge
- Konsistente IDE-Konfiguration

## Technische Konzepte

### Infrastructure as Code
- Proxmox-Management über CLI/API
- Ansible für Systemkonfiguration
- Kubernetes Manifeste für Workload-Management
- Versionierung in Git

### Storage-Konzept
- Dokumente direkt auf NAS (via NFS)
- Datenbanken auf lokalen SSDs der Hosts
- Backups von lokalen Daten auf NAS
- NAS-Backup auf externe USB-Platte

### Konfigurations-Management
- Trennung zwischen Code (Repository) und Konfiguration (extern)
- Kubernetes-native Konfiguration über ConfigMaps und Secrets
- Beispiel-Konfigurationen im Repository als Dokumentation
- Sensitive Daten ausschließlich in externem Config-Verzeichnis

#### Repository-Struktur für Konfigurationen
```
kubernetes/
├── base/                          # Manifeste und Templates
│   ├── ingress/
│   │   ├── configmap.yaml        # ConfigMap Structure
│   │   └── deployment.yaml
│   └── storage/
│       ├── secret.yaml           # Secret Structure
│       └── classes.yaml
│
└── config.examples/              # Dokumentation
    ├── secrets.example/
    │   ├── nas-credentials.yaml
    │   └── certificates.yaml
    └── configmaps.example/
        ├── ingress-config.yaml
        └── storage-config.yaml
```

#### Externe Konfiguration
```
homelab-config/                   # Gemounted, nicht im Repository
└── kubernetes/
    ├── secrets/
    │   ├── nas-credentials.yaml
    │   └── certificates.yaml
    └── configmaps/
        ├── ingress-config.yaml
        └── storage-config.yaml
```

### Development Environment
- VSCode Dev Container als Basis
- Integrierte CLI-Tools:
  - kubectl, helm, kustomize für Kubernetes
  - talosctl für OS-Management
  - Proxmox CLI für VM-Management
  - Ansible für Konfiguration
- Dokumentations-Tools:
  - PlantUML für Diagramme
  - Excalidraw für Skizzen
  - Markdown für Texte

### Projektstruktur
- Klare Trennung von Infrastruktur und Anwendungen
- Zentrale Dokumentation
- Wiederverwendbare Scripts
- Automatisierung über Makefile

## Projektstruktur

```
infrastructure-repo/
├── .devcontainer/                  # Development Container
│   ├── scripts/                    # Container Setup Scripts
│   │   └── post-create.sh         # Post-Creation Konfiguration
│   ├── config/                     # Container Konfiguration
│   │   ├── .zshrc
│   │   └── .oh-my-zsh/
│   ├── Dockerfile
│   ├── devcontainer.json
│   └── docker-compose.yml          # Für PlantUML/Excalidraw Server
│
├── .vscode/                        # VSCode Konfiguration
│   ├── extensions.json
│   └── settings.json
│
├── docs/                           # Dokumentation
│   ├── architecture/               # Architekturdiagramme
│   ├── runbooks/                   # Betriebshandbücher
│   └── setup/                      # Setup-Anleitungen
│
├── infrastructure/                 # Infrastructure Management
│   ├── ansible/
│   │   ├── inventory/
│   │   ├── roles/
│   │   └── playbooks/
│   │
│   ├── proxmox/                   # Proxmox Management
│   │   ├── templates/
│   │   └── scripts/
│   │
│   └── talos/                     # Talos Konfiguration
│       ├── controlplane.yaml
│       └── worker.yaml
│
├── kubernetes/                     # Kubernetes Manifeste
│   ├── base/                      # Basis-Konfiguration
│   │   ├── storage/
│   │   ├── networking/
│   │   └── monitoring/
│   │
│   └── apps/                      # Applikationen
│       ├── paperless/
│       ├── nextcloud/
│       └── minio/
│
├── scripts/                        # Hilfsskripte
│   ├── bootstrap/
│   │   ├── install-tools.sh
│   │   └── setup-cluster.sh
│   │
│   └── maintenance/
│       ├── backup.sh
│       └── update.sh
│
├── .gitignore
├── Makefile                       # Automatisierung häufiger Tasks
└── README.md
```

### Verzeichnisstruktur Details

#### .devcontainer/
- Enthält alle Konfigurationen für die Entwicklungsumgebung
- Dockerfile definiert die Toolchain
- Docker Compose für zusätzliche Dienste wie PlantUML

#### docs/
- Zentrale Dokumentation des Projekts
- Architekturdiagramme in PlantUML/Excalidraw
- Betriebshandbücher und Setup-Anleitungen

#### infrastructure/
- Ansible für Host-Konfiguration
- Proxmox Templates und Management-Skripte
- Talos OS Konfiguration für Kubernetes Nodes

#### kubernetes/
- Basis-Konfiguration für Cluster-Services
- Applikations-spezifische Manifeste
- Kustomize für Umgebungsspezifische Anpassungen

#### scripts/
- Bootstrap-Skripte für initiales Setup
- Wartungsskripte für reguläre Aufgaben
- Backup und Update Automatisierung

## Nächste Schritte

1. Setup Development Container
2. Basis-Infrastruktur Konfiguration
3. Kubernetes Cluster Setup
4. Core-Services Installation
5. Anwendungs-Deployment
6. Monitoring und Backup-Implementierung