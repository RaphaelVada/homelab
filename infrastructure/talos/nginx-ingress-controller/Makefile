# Makefile für Nginx Ingress Controller

# Standardvariablen
KUBECTL := kubectl
MANIFESTS_DIR := $(CURDIR)
INGRESS_NAMESPACE := ingress-nginx
INGRESS_VERSION := v1.12.2

# Offizielle Ingress Controller Manifeste URL
INGRESS_MANIFEST_URL := https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-$(INGRESS_VERSION)/deploy/static/provider/cloud/deploy.yaml

# Lokale Manifest-Dateien
INGRESS_LOCAL_MANIFEST := $(MANIFESTS_DIR)/ingress-nginx.yaml
INGRESS_CUSTOMIZATION := $(MANIFESTS_DIR)/ingress-customization.yaml
INGRESS_TEST := $(MANIFESTS_DIR)/ingress-test.yaml

# Nginx Ingress Controller Manifeste herunterladen
.PHONY: ingress-update
ingress-update:
	@echo "Lade Nginx Ingress Controller Manifeste ($(INGRESS_VERSION)) herunter..."
	@curl -sSL $(INGRESS_MANIFEST_URL) -o $(INGRESS_LOCAL_MANIFEST)
	@echo "Nginx Ingress Controller Manifeste wurden nach $(INGRESS_LOCAL_MANIFEST) heruntergeladen."

# Nginx Ingress Controller installieren
.PHONY: ingress-deploy
ingress-deploy:
	@echo "Installiere Nginx Ingress Controller im Kubernetes-Cluster..."
	@if [ ! -f $(INGRESS_LOCAL_MANIFEST) ]; then \
		echo "Manifeste nicht gefunden. Führe ingress-update aus..."; \
		$(MAKE) ingress-update; \
	fi

	@echo "Wende Nginx Ingress Controller Manifeste an..."
	@$(KUBECTL) apply -f $(INGRESS_LOCAL_MANIFEST)

	@echo "Warte, bis Ingress Controller Deployment bereit ist..."
	@$(KUBECTL) -n $(INGRESS_NAMESPACE) wait --for=condition=available deployment/ingress-nginx-controller --timeout=90s || echo "Timeout beim Warten auf Ingress Controller"

	@if [ -f $(INGRESS_CUSTOMIZATION) ]; then \
		echo "Wende benutzerdefinierte Anpassungen an..."; \
		$(KUBECTL) apply -f $(INGRESS_CUSTOMIZATION); \
	fi

	@echo "Nginx Ingress Controller wurde installiert. Die externe IP wird von MetalLB zugewiesen."
	@echo "Überprüfe mit: kubectl -n $(INGRESS_NAMESPACE) get service ingress-nginx-controller"

# Nginx Ingress Controller Status anzeigen
.PHONY: ingress-status
ingress-status:
	@echo "Nginx Ingress Controller Status:"
	@echo "Pods:"
	@$(KUBECTL) -n $(INGRESS_NAMESPACE) get pods -l app.kubernetes.io/name=ingress-nginx
	@echo "\nService und IP-Adresse:"
	@$(KUBECTL) -n $(INGRESS_NAMESPACE) get service ingress-nginx-controller
	@echo "\nIngress Controller Version:"
	@$(KUBECTL) -n $(INGRESS_NAMESPACE) exec -it $($(KUBECTL) -n $(INGRESS_NAMESPACE) get pods -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}') -- /nginx-ingress-controller --version || echo "Konnte Version nicht abrufen"

# Nginx Ingress Controller testen
.PHONY: ingress-test
ingress-test:
# Nginx Ingress Controller testen
.PHONY: ingress-test
ingress-test:
	@echo "Starte Ingress Controller Test..."
	@echo "1. Prüfe, ob Ingress Controller läuft..."
	@if ! $(KUBECTL) -n $(INGRESS_NAMESPACE) get deployment ingress-nginx-controller >/dev/null 2>&1; then \
		echo "   \033[0;31mFehler: Ingress Controller nicht gefunden. Bitte erst 'make ingress-deploy' ausführen.\033[0m"; \
		exit 1; \
	fi
	@echo "   Ingress Controller gefunden."

	@echo "2. Erstelle Test-Deployment, Service und Ingress..."
	@$(KUBECTL) apply -f $(INGRESS_TEST)

	@echo "3. Warte, bis Test-Pods bereit sind..."
	@$(KUBECTL) wait --for=condition=ready pod -l app=ingress-test --timeout=60s

	@echo "4. Warte, bis die Ingress-Ressource verarbeitet wurde (15 Sekunden)..."
	@sleep 15

	@echo "5. Hole Ingress Controller IP..."
	@IP=$$($(KUBECTL) -n $(INGRESS_NAMESPACE) get service ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && \
	if [ -z "$$IP" ]; then \
		echo "   \033[0;31mFehler: Keine IP-Adresse für den Ingress Controller gefunden. MetalLB funktioniert möglicherweise nicht.\033[0m"; \
		echo "   Prüfe den Service-Status:"; \
		$(KUBECTL) -n $(INGRESS_NAMESPACE) get service ingress-nginx-controller; \
		exit 1; \
	fi && \
	echo "   Ingress Controller IP: $$IP" && \
	echo "6. Teste Zugriff über Ingress (mit Host-Header)..." && \
	RESPONSE=$$(curl -s -o /dev/null -w "%{http_code}" -H "Host: test.ingress.local" http://$$IP/ --max-time 5) && \
	echo "   HTTP-Status: $$RESPONSE" && \
	if [ "$$RESPONSE" = "200" ]; then \
		echo "   \033[0;32mErfolgreich! Ingress Controller funktioniert.\033[0m"; \
		echo "   Erste Zeilen der HTML-Antwort:"; \
		curl -s -H "Host: test.ingress.local" http://$$IP/ | head -n 10; \
	else \
		echo "   \033[0;31mFehler: Konnte keine Verbindung über Ingress herstellen oder falscher Status-Code.\033[0m"; \
		echo "   Debug-Informationen:"; \
		echo "   - Ping zur Ingress-IP:"; \
		ping -c 1 $$IP || echo "     Ping fehlgeschlagen"; \
		echo "   - Direkte Verbindung zum Port 80:"; \
		curl -v http://$$IP/ 2>&1 | grep -E "Connected|HTTP/|Received" || echo "     Verbindung fehlgeschlagen"; \
		echo "   - Ingress-Ressource:"; \
		$(KUBECTL) describe ingress ingress-test; \
		echo "   - Ingress Controller Logs:"; \
		$(KUBECTL) -n $(INGRESS_NAMESPACE) logs -l app.kubernetes.io/name=ingress-nginx --tail=20; \
	fi

# Ingress Test aufräumen
.PHONY: ingress-test-clean
ingress-test-clean:
	@echo "Entferne Ingress Test-Ressourcen..."
	@-$(KUBECTL) delete -f $(INGRESS_TEST) 2>/dev/null || true
	@echo "Test-Ressourcen wurden entfernt."

# Nginx Ingress Controller deinstallieren
.PHONY: ingress-uninstall
ingress-uninstall:
	@echo "Entferne Nginx Ingress Controller..."
	@-$(KUBECTL) delete -f $(INGRESS_LOCAL_MANIFEST) 2>/dev/null || true
	@echo "Nginx Ingress Controller wurde entfernt."
