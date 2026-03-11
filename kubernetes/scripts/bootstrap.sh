#!/usr/bin/env bash

set -e

# Safely resolve the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="cloudmason-dev"

echo "🚀 Bootstrapping CloudMason K3d Cluster: $CLUSTER_NAME"

# 1. Create K3d cluster with standard ports exposed
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
  k3d cluster create "$CLUSTER_NAME" \
    --servers 1 \
    --agents 2 \
    --port "80:80@loadbalancer" \
    --port "443:443@loadbalancer" \
    --wait
else
  echo "✅ Cluster $CLUSTER_NAME already exists."
fi

# Set context
kubectl config use-context "k3d-$CLUSTER_NAME"

# 2. Apply Base Namespaces & RBAC so Terraform can target them
echo "📦 Applying Base Namespaces & RBAC..."
kubectl apply -f "${SCRIPT_DIR}/../base/namespaces.yaml"
kubectl apply -f "${SCRIPT_DIR}/../base/rbac.yaml"

# 3. Execute Terraform to provision the Datastores & Event Bus
echo "🏗️ Provisioning Datastores with Terraform..."
cd "${SCRIPT_DIR}/../../terraform/environments/dev"

terraform init
terraform apply -auto-approve

echo "✅ Phase 1 Complete. Infrastructure foundation is ready."
