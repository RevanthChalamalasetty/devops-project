#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
CLUSTER_NAME="devops-cluster"
PERSISTENT_DIR="$(dirname "$0")/../terraform/persistent"
CLUSTER_DIR="$(dirname "$0")/../terraform/cluster"

echo "☀️  Starting up..."

echo "▶ Starting Jenkins EC2..."
JENKINS_ID=$(cd "${PERSISTENT_DIR}" && terraform output -raw jenkins_instance_id)
aws ec2 start-instances --instance-ids "${JENKINS_ID}" --region "${REGION}" > /dev/null
aws ec2 wait instance-running --instance-ids "${JENKINS_ID}" --region "${REGION}"
JENKINS_URL=$(cd "${PERSISTENT_DIR}" && terraform output -raw jenkins_url)
echo "  Jenkins ready: ${JENKINS_URL}"

echo "▶ Applying cluster stack (~15 min)..."
cd "${CLUSTER_DIR}"
terraform apply -auto-approve

echo "▶ Updating kubeconfig..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

echo "▶ Checking cluster health..."
kubectl get nodes
kubectl get pods -A

echo ""
echo "✅ Environment ready!"
