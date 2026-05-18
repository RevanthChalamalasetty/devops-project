output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "igw_id" {
  value = aws_internet_gateway.main.id
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  value = aws_eip.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_ssh" {
  value = "ssh -i ~/.ssh/devops-key ec2-user@${aws_eip.jenkins.public_ip}"
}

output "jenkins_role_arn" {
  value = aws_iam_role.jenkins.arn
}
