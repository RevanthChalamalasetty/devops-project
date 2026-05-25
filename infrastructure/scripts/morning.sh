#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
CLUSTER_NAME="devops-cluster"
CLUSTER_DIR="$(dirname "$0")/../terraform/cluster"

echo "☀️  Good morning — starting the DevOps environment"
echo "======================================================"

echo ""
echo "▶ Step 1/3: Bringing up EKS cluster (this takes ~12-15 min)..."
cd "${CLUSTER_DIR}"
terraform apply -auto-approve

echo ""
echo "▶ Step 2/3: Configuring kubectl..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

echo ""
echo "▶ Step 3/3: Verifying cluster health..."
kubectl get nodes
kubectl get pods -A

echo ""
echo "======================================================"
echo "✅ Environment ready!"
echo "  Jenkins: http://192.168.1.12:8080"
echo "  EKS cluster: ${CLUSTER_NAME}"
echo "  Run tonight: ./infrastructure/scripts/evening.sh"
echo "======================================================"