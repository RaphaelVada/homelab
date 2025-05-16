# Makefile für MetalLB-Deployment

# Standardvariablen
METALLB_VERSION := v0.14.9
KUBECTL := kubectl
MANIFESTS_DIR := $(CURDIR)
METALLB_NAMESPACE := metallb-system

# Offizielle MetalLB Manifeste URL
METALLB_MANIFEST_URL := https://raw.githubusercontent.com/metallb/metallb/$(METALLB_VERSION)/config/manifests/metallb-native.yaml

# Lokale Manifest-Datei
METALLB_LOCAL_MANIFEST := $(MANIFESTS_DIR)/metallb-native.yaml
METALLB_LOCAL_CONFIG := $(MANIFESTS_DIR)/metallb-config.yaml

# MetalLB Manifeste herunterladen
.PHONY: metallb-update
metallb-update:
	@echo "Lade MetalLB Manifeste ($(METALLB_VERSION)) herunter..."
	@curl -sSL $(METALLB_MANIFEST_URL) -o $(METALLB_LOCAL_MANIFEST)
	@echo "MetalLB Manifeste wurden nach $(METALLB_LOCAL_MANIFEST) heruntergeladen."

# MetalLB installieren
.PHONY: metallb-deploy
metallb-deploy:
	@echo "Installiere MetalLB im Kubernetes-Cluster..."
	@if [ ! -f $(METALLB_LOCAL_MANIFEST) ]; then \
		echo "Manifeste nicht gefunden. Führe metallb-update aus..."; \
		$(MAKE) metallb-update; \
	fi
	@$(KUBECTL) apply -f $(METALLB_LOCAL_MANIFEST)

	@echo "Warte 5 Sekunden auf Initialisierung der Komponenten..."
	@sleep 5

	@$(KUBECTL) apply -f $(METALLB_LOCAL_CONFIG)

	@echo "MetalLB wurde installiert. Prüfe den Status mit: kubectl -n metallb-system get pods"

# MetalLB vollständig deinstallieren
.PHONY: metallb-uninstall
metallb-uninstall:
	@echo "Entferne MetalLB-Konfiguration..."
	@-$(KUBECTL) delete ipaddresspools.metallb.io --all -n metallb-system 2>/dev/null || true
	@-$(KUBECTL) delete l2advertisements.metallb.io --all -n metallb-system 2>/dev/null || true

	@echo "Entferne MetalLB-Komponenten..."
	@-$(KUBECTL) delete -f $(METALLB_LOCAL_MANIFEST) 2>/dev/null || true
	@-$(KUBECTL) delete -f $(METALLB_MANIFEST_URL) 2>/dev/null || true

	@echo "Entferne den Namespace und verbleibende Webhooks..."
	@-$(KUBECTL) delete validatingwebhookconfiguration metallb-webhook-configuration --ignore-not-found 2>/dev/null || true
	@-$(KUBECTL) delete ns metallb-system --grace-period=0 --force 2>/dev/null || true

	@echo "MetalLB wurde deinstalliert. Eventuelle LoadBalancer-Services haben jetzt keinen externen IP-Provider mehr."m

# MetalLB Test mit Nginx
.PHONY: metallb-test
metallb-test:
	@echo "Starte MetalLB-Test mit Nginx..."
	@echo "1. Wende Nginx-Testdeployment an..."
	@$(KUBECTL) apply -f $(MANIFESTS_DIR)/metallb-test-deployment.yaml

	@echo "2. Warte, bis Nginx-Pods bereit sind..."
	@$(KUBECTL) wait --for=condition=ready pod -l app=nginx-test --timeout=60s

	@echo "3. Warte, bis LoadBalancer-IP zugewiesen ist (10 Sekunden)..."
	@sleep 10

	@echo "4. Zeige Nginx-Service mit zugewiesener IP..."
	@$(KUBECTL) get service nginx-test

	@echo "5. Hole zugewiesene IP-Adresse..."
	@IP=$$($(KUBECTL) get service nginx-test -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && \
	echo "   Zugewiesene IP: $$IP" && \
	echo "6. Teste Verbindung..." && \
	RESPONSE=$$(curl -s -o /dev/null -w "%{http_code}" http://$$IP) && \
	echo "   HTTP-Status: $$RESPONSE" && \
	if [ "$$RESPONSE" = "200" ]; then \
		echo "   \033[0;32mErfolgreich! MetalLB funktioniert.\033[0m"; \
		curl -s http://$$IP | head -n 20; \
	else \
		echo "   \033[0;31mFehler: Konnte keine Verbindung herstellen.\033[0m"; \
	fi

	@echo "Entferne Nginx-Testdeployment..."
	@-$(KUBECTL) delete -f $(MANIFESTS_DIR)/metallb-test-deployment.yaml
	@echo "Test-Ressourcen wurden entfernt."
