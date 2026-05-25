resource "aws_iam_user" "jenkins" {
  name = "${var.project_name}-jenkins"
  tags = { Project = var.project_name }
}

resource "aws_iam_access_key" "jenkins" {
  user = aws_iam_user.jenkins.name
}

resource "aws_iam_user_policy" "jenkins_ecr" {
  name = "ecr-push"
  user = aws_iam_user.jenkins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:*:repository/${var.project_name}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "jenkins_eks" {
  name = "eks-access"
  user = aws_iam_user.jenkins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Resource = "*"
    }]
  })
}
