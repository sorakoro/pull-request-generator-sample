CLUSTER_NAME := pull-request-generator-sample

.PHONY: cluster-create cluster-delete ingress-install argocd-install argocd-setup argocd-password argocd-port-forward

cluster-create:
	kind create cluster --name $(CLUSTER_NAME) --config kind-config.yaml

ingress-install:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

argocd-install:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --namespace argocd \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=120s

argocd-setup:
	kubectl apply -f github-token-secret.yaml
	kubectl apply -f applicationset.yaml

argocd-password:
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

argocd-port-forward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

cluster-delete:
	kind delete cluster --name $(CLUSTER_NAME)
