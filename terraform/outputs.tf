# GitHub Actions Required Outputs
output "AWS_REGION" {
  description = "AWS region for GitHub Actions"
  value       = data.aws_region.current.name
}

output "AWS_ACCOUNT_ID" {
  description = "AWS account ID for GitHub Actions"
  value       = data.aws_caller_identity.current.account_id
}

output "AWS_ROLE_ARN" {
  description = "GitHub Actions IAM role ARN"
  value       = aws_iam_role.github_actions.arn
}

output "ECR_REPOSITORY" {
  description = "ECR repository name"
  value       = aws_ecr_repository.main.name
}

output "ECS_CLUSTER" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ECS_SERVICE" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "CODEDEPLOY_APPLICATION" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.main.name
}

output "CODEDEPLOY_DEPLOYMENT_GROUP" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.main.deployment_group_name
}

output "CONTAINER_NAME" {
  description = "Container name for deployment"
  value       = var.project_name
}

# Additional Useful Outputs
output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.main.repository_url
}

output "github_secrets_table" {
  description = "GitHub secrets configuration table"
  value = <<-EOT
# GitHub Secrets Configuration

Copy and paste these values into your GitHub repository secrets:

| Secret Name | Value |
|-------------|-------|
| AWS_REGION | ${data.aws_region.current.name} |
| AWS_ACCOUNT_ID | ${data.aws_caller_identity.current.account_id} |
| AWS_ROLE_ARN | ${aws_iam_role.github_actions.arn} |
| ECR_REPOSITORY | ${aws_ecr_repository.main.name} |
| ECS_CLUSTER | ${aws_ecs_cluster.main.name} |
| ECS_SERVICE | ${aws_ecs_service.main.name} |
| CODEDEPLOY_APPLICATION | ${aws_codedeploy_app.main.name} |
| CODEDEPLOY_DEPLOYMENT_GROUP | ${aws_codedeploy_deployment_group.main.deployment_group_name} |
| CONTAINER_NAME | ${var.project_name} |
| CONTAINER_PORT | ${var.container_port} |

Optional secrets:
| Secret Name | Value |
|-------------|-------|
| SLACK_WEBHOOK_URL | (your Slack webhook URL) |
  EOT
}

output "deployment_commands" {
  description = "Useful deployment commands"
  value = <<-EOT
# Useful Commands

## Terraform
terraform init
terraform plan
terraform apply
terraform destroy

## AWS CLI
# Check ECS service
aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.main.name}

# Check task definitions
aws ecs list-task-definitions

# Check deployments
aws deploy list-deployments --application-name ${aws_codedeploy_app.main.name} --deployment-group-name ${aws_codedeploy_deployment_group.main.deployment_group_name}

# Check load balancer
aws elbv2 describe-load-balancers --names ${aws_lb.main.name}

# Check target groups
aws elbv2 describe-target-groups --names ${aws_lb_target_group.blue.name} ${aws_lb_target_group.green.name}
  EOT
}
