# ECS Fargate CI/CD Pipeline with GitHub Actions

This repository contains a complete Infrastructure-as-Code setup for deploying Dockerized applications to AWS ECS Fargate using Blue/Green deployment with GitHub Actions and AWS CodeDeploy.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Actions│────│   Amazon ECR    │────│  ECS Fargate    │
│                 │    │                 │    │                 │
│ • Build & Push  │    │ • Docker Images │    │ • Blue/Green    │
│ • Deploy        │    │ • Image Scanning│    │ • Auto Rollback │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │ AWS CodeDeploy  │    │ Application     │
                       │                 │    │ Load Balancer    │
                       │ • Blue/Green    │    │                 │
                       │ • Traffic Shift │    │ • Health Checks  │
                       │ • Auto Rollback │    │ • SSL Termination│
                       └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- Docker installed locally
- GitHub repository with your application code

### 1. Clone and Setup

```bash
git clone <your-repo>
cd <your-repo>
```

### 2. Configure Terraform Variables

Create a `terraform.tfvars` file:

```hcl
# Required Variables
github_owner = "your-github-username"
github_repo  = "your-repository-name"

# Optional Variables (with defaults)
aws_region        = "ap-south-1"
project_name      = "myapp"
environment       = "production"
container_port    = 3000
container_cpu     = 256
container_memory  = 512
desired_count     = 1

# Optional: Use existing VPC
# existing_vpc_id              = "vpc-xxxxxxxxx"
# existing_private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
# existing_public_subnet_ids  = ["subnet-aaaaaaa", "subnet-bbbbbbb"]
```

### 3. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the changes
terraform apply
```

### 4. Configure GitHub Secrets

After `terraform apply` completes, copy the outputs to your GitHub repository secrets:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each secret from the Terraform output

The required secrets are:
- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `AWS_ROLE_ARN`
- `ECR_REPOSITORY`
- `ECS_CLUSTER`
- `ECS_SERVICE`
- `CODEDEPLOY_APPLICATION`
- `CODEDEPLOY_DEPLOYMENT_GROUP`
- `CONTAINER_NAME`
- `CONTAINER_PORT`

Optional:
- `SLACK_WEBHOOK_URL` (for notifications)

### 5. Deploy Your Application

1. Add your application code to the repository
2. Ensure you have a `Dockerfile` in the root
3. Push to the `main` branch

```bash
git add .
git commit -m "Initial application deployment"
git push origin main
```

The GitHub Actions workflow will automatically:
- Build your Docker image
- Push it to ECR
- Update the ECS task definition
- Trigger a blue/green deployment via CodeDeploy
- Monitor the deployment and rollback on failure

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── main.tf                 # VPC and networking
│   ├── providers.tf            # AWS provider configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── ecr.tf                  # ECR repository
│   ├── ecs.tf                  # ECS cluster and service
│   ├── alb.tf                  # Application Load Balancer
│   ├── iam.tf                  # IAM roles and policies
│   └── codedeploy.tf           # CodeDeploy configuration
├── Dockerfile                  # Your application container
└── README.md                   # This file
```

## 🔧 Configuration Details

### Terraform Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `github_owner` | GitHub repository owner | - | ✅ |
| `github_repo` | GitHub repository name | - | ✅ |
| `aws_region` | AWS region | `ap-south-1` | ❌ |
| `project_name` | Project name for resources | `myapp` | ❌ |
| `container_port` | Application port | `3000` | ❌ |
| `container_cpu` | CPU units per task | `256` | ❌ |
| `container_memory` | Memory per task (MB) | `512` | ❌ |
| `desired_count` | Number of tasks | `1` | ❌ |

### GitHub Actions Workflow Features

- ✅ OIDC-based authentication (no AWS keys needed)
- ✅ Docker image building and pushing to ECR
- ✅ Dynamic task definition updates
- ✅ Blue/Green deployment with CodeDeploy
- ✅ Deployment monitoring and automatic rollback
- ✅ Slack notifications (optional)
- ✅ Concurrency control to prevent parallel deployments
- ✅ Comprehensive logging and error handling

### Security Features

- ✅ GitHub OIDC for secure authentication
- ✅ Least privilege IAM policies
- ✅ Private subnets for ECS tasks
- ✅ Security groups with minimal required ports
- ✅ ECR image scanning enabled
- ✅ CloudWatch logging enabled

## 🧪 Testing Locally

### Test Docker Build

```bash
# Build the image locally
docker build -t myapp:test .

# Run the container
docker run -p 3000:3000 myapp:test

# Test the health endpoint
curl http://localhost:3000/health
```

### Test Terraform Changes

```bash
cd terraform

# Validate syntax
terraform validate

# Format code
terraform fmt

# Check for security issues
terraform plan -detailed-exitcode
```

## 🚨 Troubleshooting

### Common Issues

#### 1. GitHub Actions Fails with "Access Denied"
- Ensure GitHub OIDC role is properly configured
- Check that the GitHub repository matches the OIDC trust policy
- Verify IAM role has the required permissions

#### 2. Deployment Times Out
- Check that your application has a `/health` endpoint
- Ensure the health endpoint responds within 5 seconds
- Verify the container port matches `CONTAINER_PORT` secret

#### 3. CodeDeploy Rollback
- Check CloudWatch logs for the ECS service
- Verify the application starts correctly
- Ensure all dependencies are available

#### 4. Load Balancer Health Checks Fail
- Confirm the health endpoint path is `/health`
- Check security group rules allow traffic from ALB
- Verify the application binds to the correct port

### Debug Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster myapp-cluster --services myapp-service

# Check recent deployments
aws deploy list-deployments --application-name myapp-codedeploy-app

# Check task definition
aws ecs describe-task-definition --task-definition myapp-task

# Check ALB target groups
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View CloudWatch logs
aws logs tail /aws/ecs/myapp --follow
```

## 🔄 Deployment Process

1. **Code Push**: Developer pushes to `main` branch
2. **GitHub Actions Trigger**: Workflow starts automatically
3. **Docker Build**: Application is built into Docker image
4. **ECR Push**: Image is pushed to Amazon ECR with commit SHA tag
5. **Task Definition**: New ECS task definition is registered
6. **CodeDeploy**: Blue/Green deployment is triggered
7. **Health Checks**: CodeDeploy monitors new version health
8. **Traffic Shift**: If healthy, traffic is shifted to new version
9. **Cleanup**: Old task set is terminated after 5 minutes
10. **Notification**: Success/failure notification sent

## 📊 Monitoring

### CloudWatch Metrics
- ECS service CPU/memory utilization
- ALB request count and latency
- Target group health check status
- CodeDeploy deployment status

### Logging
- Application logs: `/aws/ecs/myapp`
- ECS agent logs: `/aws/ecs/ecs-agent`
- CodeDeploy logs: Available in AWS console

## 🛠️ Maintenance

### Regular Tasks
- Review and update IAM policies
- Monitor CloudWatch costs
- Update Terraform providers
- Rotate secrets periodically
- Review security group rules

### Scaling
- Update `desired_count` in Terraform
- Configure auto-scaling policies
- Consider multiple availability zones
- Implement database connections

## 📚 Additional Resources

- [AWS ECS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/latest/userguide/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
