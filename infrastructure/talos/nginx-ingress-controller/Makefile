.PHONY: install-nginx
install-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx/
	helm template ingress-nginx --repo https://kubernetes.github.io/ingress-nginx/ --version 4.12.2 --namespace ingress-nginx > ingress-nginx.helm.yaml
	kubectl create namespace ingress-nginx
	kubectl apply -f ingress-nginx.helm.yaml
