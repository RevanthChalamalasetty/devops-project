#!/bin/bash
set -euo pipefail

AWS_REGION="ap-south-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="devops-project-tfstate-${ACCOUNT_ID}"
DYNAMODB_TABLE="devops-tf-lock"

echo "Account : ${ACCOUNT_ID}"
echo "Bucket  : ${BUCKET_NAME}"
echo "Table   : ${DYNAMODB_TABLE}"

# S3 bucket
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "Bucket already exists, skipping."
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}"

  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "S3 bucket created."
fi

# DynamoDB table
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" 2>/dev/null; then
  echo "DynamoDB table already exists, skipping."
else
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"

  aws dynamodb wait table-exists \
    --table-name "${DYNAMODB_TABLE}" \
    --region "${AWS_REGION}"

  echo "DynamoDB table created."
fi

echo ""
echo "Done. Your bucket name is: ${BUCKET_NAME}"
echo "Paste this into both backend.tf files."
