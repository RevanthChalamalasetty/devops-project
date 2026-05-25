#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
CLUSTER_DIR="$(dirname "$0")/../terraform/cluster"

echo "🌙 Shutting down — destroying cluster stack..."
cd "${CLUSTER_DIR}"
terraform destroy -auto-approve

echo ""
echo "✅ Done. EKS and NAT Gateway stopped. Billing halted."
echo "   Preserved: S3 state, ECR images, VPC, IAM user"
echo "   Jenkins on laptop: still running as always"

