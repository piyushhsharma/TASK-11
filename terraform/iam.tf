# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]
}

# GitHub Actions IAM Role
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# GitHub Actions IAM Policy
resource "aws_iam_policy" "github_actions" {
  name        = "${var.project_name}-github-actions-policy"
  description = "Policy for GitHub Actions CI/CD"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ECRLoginAndPush"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Sid = "ECRRepositoryAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.main.arn
      },
      {
        Sid = "ECSManagement"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeServices",
          "ecs:DescribeClusters",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Sid = "CodeDeployManagement"
        Effect = "Allow"
        Action = [
          "codedeploy:GetApplication",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:ListDeployments",
          "codedeploy:StopDeployment"
        ]
        Resource = [
          aws_codedeploy_app.main.arn,
          aws_codedeploy_deployment_group.main.arn,
          "arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deployment-config:CodeDeployDefault.ECSAllAtOnce"
        ]
      },
      {
        Sid = "LoadBalancerAccess"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      },
      {
        Sid = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/*"
      },
      {
        Sid = "IAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# CodeDeploy Service Role
resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_role.json

  tags = {
    Name = "${var.project_name}-codedeploy-role"
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
