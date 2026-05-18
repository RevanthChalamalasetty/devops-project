#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
CLUSTER_NAME="devops-cluster"
INSTANCE_ID="i-0074b5ae85403ed64"
PERSISTENT_DIR="$(dirname "$0")/../terraform/persistent"
CLUSTER_DIR="$(dirname "$0")/../terraform/cluster"

echo "☀️  Good morning — starting the DevOps environment"
echo "======================================================"

echo ""
echo "▶ Step 1/4: Starting Jenkins EC2..."
CURRENT_STATE=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${REGION}" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text)

if [ "${CURRENT_STATE}" == "running" ]; then
  echo "  Jenkins is already running."
elif [ "${CURRENT_STATE}" == "stopped" ]; then
  aws ec2 start-instances --instance-ids "${INSTANCE_ID}" --region "${REGION}" > /dev/null
  echo "  Waiting for Jenkins to reach running state..."
  aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}" --region "${REGION}"
  echo "  Jenkins is running."
else
  echo "  Jenkins is in state: ${CURRENT_STATE} — check AWS console."
  exit 1
fi

echo ""
echo "▶ Step 2/4: Bringing up EKS cluster (this takes ~12-15 min)..."
cd "${CLUSTER_DIR}"
terraform apply -auto-approve

echo ""
echo "▶ Step 3/4: Configuring kubectl..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

echo ""
echo "▶ Step 4/4: Verifying cluster health..."
kubectl get nodes
kubectl get pods -A

echo ""
echo "======================================================"
echo "✅ Environment ready!"
echo "  Jenkins: http://13.207.18.206:8080"
echo "  Run tonight: ./infrastructure/scripts/evening.sh"
echo "======================================================"
