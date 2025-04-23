# Server-Konfiguration: Deutsche Locale installieren
srv-cfg-locale:
	@echo "=== Konfiguriere deutsche Locale auf $(SERVER_IP) ==="
	ssh $(SERVER_IP) "sudo apt-get update && sudo apt-get install -y locales && sudo sed -i 's/# de_DE.UTF-8/de_DE.UTF-8/' /etc/locale.gen && sudo locale-gen"
	@echo "=== Locale-Konfiguration abgeschlossen ==="# Makefile für Core-DNS Deployment

# Standardwert für die Server-IP
SERVER_IP ?= 192.168.100.153
DNS_PORT ?= 53

.PHONY: help deploy-core-dns deploy-ha-proxy secret-save secret-load

# Standardziel
help:
	@echo "Service Deployment Makefile"
	@echo ""
	@echo "Verfügbare Befehle:"
	@echo "  make deploy-core-dns SERVER_IP=<ip-adresse>  - Deployt den core-dns Service zum angegebenen Server"
	@echo "  make help                                    - Zeigt diese Hilfe an"
	@echo ""
	@echo "Beispiel:"
	@echo "  make deploy-core-dns SERVER_IP=192.168.1.100"
	@echo "  make deploy-core-dns                          # Verwendet Standard-IP: $(SERVER_IP)"

# Core-DNS Deployment
deploy-core-dns:
	@echo "=== Deploying core-dns auf $(SERVER_IP) ==="

	@echo "Synchronisiere Dateien (inkl. Auflösung von Symlinks, ohne Berechtigungen)..."
	ssh $(SERVER_IP) "mkdir -p ~/core-dns"
	rsync -rvzL --exclude '.git/' ./services/core-dns/ $(SERVER_IP):~/core-dns/
	ssh $(SERVER_IP) "mkdir -p ~/core-dns"
	rsync -rvzL --exclude '.git/' ./services/core-dns/ $(SERVER_IP):~/core-dns/

	@echo "Prüfe Service-Status..."
	@echo "Entferne eventuell vorhandene Container mit gleichem Namen..."
	ssh $(SERVER_IP) "cd ~/core-dns && docker-compose down -v 2>/dev/null || true"
	ssh $(SERVER_IP) "docker rm -f \$$(docker ps -a --filter name=coredns -q) 2>/dev/null || true"

	@echo "Starte Service neu..."
	ssh $(SERVER_IP) "cd ~/core-dns && docker-compose up -d --build"

	@echo "=== Deployment von core-dns auf $(SERVER_IP) abgeschlossen ==="


test-dns:
	@echo "=== Teste DNS-Auflösung auf $(SERVER_IP) ==="
	@echo "\n1. Test A-Record für hyper01.my.vadue.de (vom Zielserver):"
	ssh $(SERVER_IP) "dig @localhost -p $(DNS_PORT) hyper01.my.vadue.de A +short"

	@echo "\n2. Test CNAME-Record für vm01.my.vadue.de (vom Zielserver):"
	ssh $(SERVER_IP) "dig @localhost -p $(DNS_PORT) vm01.my.vadue.de CNAME +short"

	@echo "\n3. Test PTR-Record für 192.168.2.101 (vom Zielserver):"
	ssh $(SERVER_IP) "dig @localhost -p $(DNS_PORT) -x 192.168.2.101 +short"

	@echo "\n4. Test komplette Antwort für hyper01.my.vadue.de (vom Zielserver):"
	ssh $(SERVER_IP) "dig @localhost -p $(DNS_PORT) hyper01.my.vadue.de"

	@echo "\n5. Test komplette Antwort für PTR-Record (vom Zielserver):"
	ssh $(SERVER_IP) "dig @localhost -p $(DNS_PORT) -x 192.168.2.101"

	@echo "\n=== DNS-Tests vom lokalen System ==="
	@echo "\n6. Test A-Record für hyper01.my.vadue.de (vom lokalen System):"
	dig @$(SERVER_IP) -p $(DNS_PORT) hyper01.my.vadue.de A +short || echo "Fehler: Dig nicht installiert oder Server nicht erreichbar"

	@echo "\n7. Test CNAME-Record für vm01.my.vadue.de (vom lokalen System):"
	dig @$(SERVER_IP) -p $(DNS_PORT) vm01.my.vadue.de CNAME +short || echo "Fehler: Dig nicht installiert oder Server nicht erreichbar"

	@echo "\n8. Test PTR-Record für 192.168.2.101 (vom lokalen System):"
	dig @$(SERVER_IP) -p $(DNS_PORT) -x 192.168.2.101 +short || echo "Fehler: Dig nicht installiert oder Server nicht erreichbar"

	@echo "\n=== DNS-Tests abgeschlossen ==="	@echo "  make test-dns SERVER_IP=<ip-adresse>          - Testet DNS-Auflösung auf dem Server"# Server-Konfiguration: Deutsche Locale installieren

secret-save:
	vault-sync.sh to-vault

secret-load:
	vault-sync.sh from-vault




# Core-DNS Deployment
deploy-ha-proxy:
	@echo "=== Deploying ha-proxy auf $(SERVER_IP) ==="

	@echo "Synchronisiere Dateien (inkl. Auflösung von Symlinks, ohne Berechtigungen)..."
	ssh $(SERVER_IP) "mkdir -p ~/ha-proxy"
	rsync -rvzL --exclude '.git/' ./services/ha-proxy/ $(SERVER_IP):~/ha-proxy/
	ssh $(SERVER_IP) "mkdir -p ~/ha-proxy"
	rsync -rvzL --exclude '.git/' ./services/ha-proxy/ $(SERVER_IP):~/ha-proxy/

	@echo "Prüfe Service-Status..."
	@echo "Entferne eventuell vorhandene Container mit gleichem Namen..."
	ssh $(SERVER_IP) "cd ~/ha-proxy && docker-compose down -v 2>/dev/null || true"
	ssh $(SERVER_IP) "docker rm -f \$$(docker ps -a --filter name=haproxy -q) 2>/dev/null || true"

	@echo "Starte Service neu..."
	ssh $(SERVER_IP) "cd ~/ha-proxy && docker-compose up -d --build"

	@echo "=== Deployment von ha-proxy auf $(SERVER_IP) abgeschlossen ==="
