.PHONY: cluster-up cluster-down deploy-app password-argocd forward-argocd

cluster-up:
	chmod +x cluster/bootstrap.sh
	./cluster/bootstrap.sh

cluster-down:
	kind delete cluster --name lab-k8s-local

password-argocd:
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo ""

forward-argocd:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

deploy-local-app:
	kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f manifests/core-app/