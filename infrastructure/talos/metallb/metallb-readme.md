# MetalLB - Load Balancer für Kubernetes

MetalLB ist ein Load-Balancer-Controller für Kubernetes, der es ermöglicht, LoadBalancer-Services in Umgebungen ohne Cloud-Provider zu nutzen. In diesem Ordner befinden sich die Konfigurationsdateien für die MetalLB-Installation in unserem Homelab-Cluster.

## Offizielle Ressourcen

- **Website**: [MetalLB.io](https://metallb.io/)
- **GitHub Repository**: [metallb/metallb](https://github.com/metallb/metallb)
- **Dokumentation**: [MetalLB Dokumentation](https://metallb.io/documentation/)
- **Quick Start Guide**: [Installation](https://metallb.io/installation/)

## Nützliche Tutorials & Guides

- [MetalLB mit Layer 2 Konfiguration](https://metallb.io/configuration/_tutorials/layer2/)
- [Kubernetes.io Blog: MetalLB Einführung](https://kubernetes.io/blog/2020/02/07/kubernetes-on-premise-with-kubeadm-and-metallb/)
- [Digital Ocean: How To Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes Using Helm](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes)
- [Packet Labs: BGP mit MetalLB Tutorial](https://github.com/packet-labs/BGP-MetalLB-Tutorial)

## Architektur

MetalLB operiert in zwei Modi:
1. **Layer 2 Modus**: Verwendet ARP (für IPv4) oder NDP (für IPv6) zur Bekanntmachung von Services
2. **BGP Modus**: Verwendet das Border Gateway Protocol für Service-Bekanntmachungen

In unserem Homelab verwenden wir den **Layer 2 Modus**, der einfacher zu konfigurieren ist und keine spezielle Netzwerkhardware benötigt.

## Konfiguration

Unsere MetalLB-Konfiguration besteht aus:

- `ipaddresspool.yaml`: Definiert den IP-Adressbereich, den MetalLB verwenden darf
- `l2advertisement.yaml`: Konfiguriert den Layer 2 Modus und welche IP-Pools verwendet werden

## Deployment

MetalLB kann mit den bereitgestellten Make-Targets installiert werden:

```bash
# MetalLB-Manifeste aktualisieren (von der offiziellen Quelle)
make metallb-update

# MetalLB im Cluster installieren
make metallb-deploy
```

## Prüfen der Installation

Nach der Installation kann der Status wie folgt überprüft werden:

```bash
# Alle MetalLB-Ressourcen anzeigen
kubectl -n metallb-system get all

# IPAddressPools prüfen
kubectl -n metallb-system get ipaddresspools.metallb.io

# L2Advertisements prüfen
kubectl -n metallb-system get l2advertisements.metallb.io
```

## Troubleshooting

### Häufige Probleme und Lösungen

- **Keine LoadBalancer-IP zugewiesen**: Überprüfe die IPAddressPool-Konfiguration und stelle sicher, dass der IP-Bereich korrekt und verfügbar ist.
- **ARP-/NDP-Probleme**: Stelle sicher, dass die MetalLB-Knoten im gleichen Netzwerksegment wie der konfigurierte IP-Bereich sind.
- **Logs überprüfen**: `kubectl -n metallb-system logs -l app=metallb -c controller`

### Nützliche Debug-Befehle

```bash
# Controller-Logs anzeigen
kubectl -n metallb-system logs -l component=controller

# Speaker-Logs anzeigen (auf allen Nodes)
kubectl -n metallb-system logs -l component=speaker
```

## Weiterführende Informationen

- [MetalLB FAQ](https://metallb.io/faq/)
- [Konzepte und Architektur](https://metallb.io/concepts/)
- [MetalLB Konfigurationsreferenz](https://metallb.io/configuration/)
