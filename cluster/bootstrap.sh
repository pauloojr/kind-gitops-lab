#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="lab-k8s-local"

echo "[1/4] Provisionando cluster Kind..."
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster --name "${CLUSTER_NAME}" --config cluster/kind-config.yaml
else
  echo "Cluster ${CLUSTER_NAME} já existe. Pulando criação."
fi

echo "[2/4] Aplicando NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Aguardando prontidão do ingress-nginx..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "[3/4] Instalando Argo CD via Server-Side Apply..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Aplicar manifestos com --server-side para contornar o limite de 262144 bytes de annotations nas CRDs
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side

echo "Aguardando pods do Argo CD..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=240s

echo "[4/4] Setup concluido com sucesso."
echo "Para obter a senha do Argo CD:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"