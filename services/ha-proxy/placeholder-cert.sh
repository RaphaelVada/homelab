#!/bin/bash

# Erstellt ein selbst-signiertes SSL-Zertifikat für HAProxy im Entwicklungsmodus
# In der Produktionsumgebung sollten echte Zertifikate verwendet werden

mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/placeholder.key \
  -out certs/placeholder.crt \
  -subj "/CN=hyper.my.vadue.de" \
  -addext "subjectAltName = DNS:hyper.my.vadue.de"

# HAProxy benötigt cert+key in einer Datei
cat certs/placeholder.crt certs/placeholder.key > certs/placeholder.pem

echo "Platzhalter-Zertifikat für Entwicklung erstellt unter certs/placeholder.pem"
echo "Hinweis: Für Produktion ein echtes Zertifikat verwenden!"
