#!/usr/bin/env bash

set -e

# Start kind cluster
echo "Starting kind cluster"
kind create cluster || :

echo "Setting context to point to kind cluster"
kubectl config use-context kind-kind

echo "Checking cluster info"
kubectl cluster-info --context kind-kind

# Deploy ArgoCD to cluster
echo "Deploying ArgoCD to cluster"
helm repo add argo-cd https://argoproj.github.io/argo-helm || :
helm upgrade --install argo-cd argo-cd/argo-cd -f argocd-values.yaml --namespace argocd --create-namespace || :

# Get login information
echo "Getting ArgoCD login password"
PASSWORD=$(kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" -n argocd | base64 -d) || :
echo "🔑 ArgoCD login information: Username: admin, password: $PASSWORD"

echo "Starting port-forward in the background so you can log in"
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443 2>&1 >/dev/null &
echo "Log in at http://localhost:8080"

# Deploy VM Operator
helm repo add vm https://victoriametrics.github.io/helm-charts/ || :
helm upgrade --install vm-operator vm/victoria-metrics-operator --namespace monitoring --create-namespace || :

# Create example ArgoApp and ArgoAppProject
echo "Creating ArgoApps and ArgoAppProjects"
kubectl apply -f argo-projects/ || :
kubectl apply -f argo-apps/ || :
