# HAProxy Reverse Proxy für Proxmox

Dieses Service-Projekt stellt einen HAProxy Reverse Proxy für Proxmox-Instanzen bereit.

## Funktionen

- HTTP zu HTTPS Weiterleitung
- Load Balancing für Proxmox Weboberfläche
- Sticky Sessions für kontinuierliche Sitzungen
- Verifikation von selbst-signierten Zertifikaten deaktiviert

## Struktur

```
/workspace/services/haproxy/
├── docker-compose.yml      # Docker Compose Konfiguration
├── config/                 # HAProxy Konfigurationsdateien
│   └── haproxy.cfg         # Hauptkonfigurationsdatei
├── certs/                  # SSL-Zertifikate
│   └── placeholder.pem     # Platzhalter-Zertifikat für Entwicklung
└── README.md               # Diese Datei
```

## Manuelle Installation

1. Verzeichnisstruktur erstellen:
   ```
   mkdir -p /workspace/services/haproxy/config
   mkdir -p /workspace/services/haproxy/certs
   ```

2. Skript zur Erstellung eines Platzhalter-Zertifikats ausführen:
   ```
   ./placeholder-cert.sh
   ```

3. Docker Compose starten:
   ```
   docker-compose up -d
   ```

## Zukünftige Erweiterungen

- SSL-Termination am HAProxy
- Dynamische Routenkonfiguration mit Ansible
- Letsencrypt-Integration

## Aktuelles Routing

- `hyper.my.vadue.de:80` → Weiterleitung auf HTTPS (Port 443)
- `hyper.my.vadue.de:443` → Load Balancing zwischen:
  - `hyper01.my.vadue.de:8006`
  - `hyper02.my.vadue.de:8006`
  - `hyper03.my.vadue.de:8006`
