# Jenkins EC2 — stop at night, start each morning.
# EBS volume persists with all config, plugins, job history.
# Public subnet + Elastic IP = direct internet, zero NAT cost.

resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Jenkins server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-jenkins-sg" }
}

resource "aws_key_pair" "jenkins" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.public_key_path))
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = aws_key_pair.jenkins.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = false
    tags = { Name = "${var.project_name}-jenkins-vol" }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "${var.project_name}-jenkins" }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "jenkins" {
  instance   = aws_instance.jenkins.id
  domain     = "vpc"
  tags       = { Name = "${var.project_name}-jenkins-eip" }
  depends_on = [aws_internet_gateway.main]
}
