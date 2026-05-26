output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "igw_id" {
  value = aws_internet_gateway.main.id
}

output "jenkins_user_arn" {
  description = "IAM user ARN — used by cluster stack for EKS access entry"
  value       = aws_iam_user.jenkins.arn
}

output "jenkins_access_key_id" {
  description = "Add to Jenkins credentials store — never commit this"
  value       = aws_iam_access_key.jenkins.id
  sensitive   = true
}

output "jenkins_secret_access_key" {
  description = "Add to Jenkins credentials store — never commit this"
  value       = aws_iam_access_key.jenkins.secret
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR URL used in Jenkinsfile for docker push"
  value       = aws_ecr_repository.spring_app.repository_url
}
