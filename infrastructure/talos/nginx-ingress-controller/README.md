# Nginx Ingress Controller für Kubernetes

Dieser Ordner enthält die Konfigurationsdateien für die Installation und Verwaltung des Nginx Ingress Controllers in unserem Kubernetes-Cluster. Der Ingress Controller ermöglicht HTTP/HTTPS-Routing zu Services im Cluster basierend auf Host und Pfad.

## Offizielle Ressourcen

- **GitHub Repository**: [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx)
- **Dokumentation**: [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- **Installation Guide**: [Installation Guide](https://kubernetes.github.io/ingress-nginx/deploy/)
- **Konfigurationsoptionen**: [ConfigMap](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)

## Nützliche Tutorials & Guides

- [Kubernetes.io: Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Digital Ocean: Nginx Ingress Controller](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes)
- [F5 DevCentral: Nginx Ingress Path Matching](https://devcentral.f5.com/s/articles/Kubernetes-Ingress-Controller-for-NGINX-Part-4-Path-Based-Routing-27158)
- https://github.com/kubernetes/ingress-nginx
  https://www.youtube.com/watch?v=N7W_nsEA-Ao

## Architektur

Der Nginx Ingress Controller läuft als Set von Pods im Cluster und wird über einen LoadBalancer-Service (MetalLB) im Netzwerk zugänglich gemacht. Er nutzt Ingress-Ressourcen, um zu bestimmen, wie HTTP-Anfragen zu verschiedenen Services geroutet werden sollen.

```
Internet -> MetalLB IP -> Nginx Ingress Controller -> Kubernetes Services -> Pods
```

## Installation

Der Nginx Ingress Controller kann mit den bereitgestellten Make-Targets installiert werden:

```bash
# Nginx Ingress Controller-Manifeste aktualisieren
make ingress-update

# Nginx Ingress Controller im Cluster installieren
make ingress-deploy
```

## Grundlegende Verwendung

Nach der Installation kannst du Ingress-Ressourcen für deine Services erstellen:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
```

## Prüfen der Installation

Nach der Installation kann der Status wie folgt überprüft werden:

```bash
# Ingress Controller Pods anzeigen
kubectl -n ingress-nginx get pods

# LoadBalancer-IP prüfen
kubectl -n ingress-nginx get service ingress-nginx-controller
```
