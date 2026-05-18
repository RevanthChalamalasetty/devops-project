#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
PERSISTENT_DIR="$(dirname "$0")/../terraform/persistent"
CLUSTER_DIR="$(dirname "$0")/../terraform/cluster"

echo "🌙 Shutting down — destroying cluster stack..."
cd "${CLUSTER_DIR}"
terraform destroy -auto-approve

echo ""
echo "⏸  Stopping Jenkins EC2..."
JENKINS_ID=$(cd "${PERSISTENT_DIR}" && terraform output -raw jenkins_instance_id)
aws ec2 stop-instances --instance-ids "${JENKINS_ID}" --region "${REGION}" > /dev/null
aws ec2 wait instance-stopped --instance-ids "${JENKINS_ID}" --region "${REGION}"

echo ""
echo "✅ Done. Cost stopped. See you tomorrow."
echo "   Preserved: S3 state, ECR images, Jenkins EBS volume"
