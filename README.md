# DevOps Engineer Practical Challenge

## Live Application
- **App URL:** http://devops-challenge-prod-alb-1796929751.us-east-1.elb.amazonaws.com
- **Health Check:** http://devops-challenge-prod-alb-1796929751.us-east-1.elb.amazonaws.com/health

---

## Architecture Overview
+----------------------+
|  Auto Scaling        |
|  ECR  CloudWatch     |
|                      |
|  +----------------+  |
|  | +------------+ |  |
|  | | Task AZ-b  | |  |
|  | | ECS Fargate| |  |
|  | +------------+ |  |
|  | +------------+ |  |
|  | | Task AZ-a  | |  |
|  | | ECS Fargate| |  |
|  | +------------+ |  |
|  | Private Subnets|  |
|  |       |        |  |
|  | +-----+------+ |  |
|  | | (Port 80)  | |  |
|  | |    ALB     | |  |
|  | +------------+ |  |
|  | Public Subnets |  |
|  |                |  |
|  | 10.0.0.0/16    |  |
|  |  VPC           |  |
|  +----------------+  |
|                      |
|        AWS           |
+----------+-----------+
v
|
+----------+-----------+
| 5. Deploy to ECS     |
| 4. Terraform Apply   |
| 3. Push to ECR       |
| 2. Build Docker Image|
| 1. Run Tests         |
|                      |
|  CI/CD Pipeline      |
|   GitHub Actions     |
+----------------------+
v
|
Developer pushes code to GitHub (main branch)

### Request Flow
1. User sends request to ALB (port 80, public internet)
2. ALB forwards to ECS Fargate Tasks (port 3000, private subnet)
3. Tasks pull images from ECR on startup
4. Tasks send logs to CloudWatch
5. Auto Scaling adjusts task count based on CPU/Memory

---

## Project Structure

└── ci-cd.yml       # GitHub Actions pipeline
└── workflows/
└── .github/
│
│           └── terraform.tfvars
│           ├── outputs.tf
│           ├── variables.tf
│           ├── main.tf
│       └── prod/           # Production environment
│   └── environments/
│   │   └── cloudwatch/     # Logs, alarms, dashboard
│   │   ├── ecs/            # ECS cluster, service, ALB, IAM
│   │   ├── ecr/            # Container registry
│   │   ├── vpc/            # VPC, subnets, NAT, route tables
│   ├── modules/
├── terraform/
│
│   └── Dockerfile          # Multi-stage production build
│   ├── package.json        # Node dependencies
│   ├── index.test.js       # Jest unit tests
│   ├── index.js            # Express application
├── app/
devops-challenge/

---

## Tech Stack

| Component | Technology | Reason |
|-----------|-----------|--------|
| Application | Node.js + Express | Lightweight, fast, easy to test |
| Containerization | Docker (multi-stage) | Small image, non-root user, secure |
| Container Registry | AWS ECR | Native AWS, image scanning built-in |
| Compute | AWS ECS Fargate | No servers to manage, auto-scaling |
| Networking | Custom VPC (2 AZs) | High availability, public/private split |
| Load Balancer | AWS ALB | Health checks, traffic routing |
| Infrastructure | Terraform (modular) | Reusable, version-controlled |
| CI/CD | GitHub Actions | Native to GitHub, no extra infra needed |
| Monitoring | AWS CloudWatch | Logs, metrics, alarms, dashboard |

---

## Deployment Steps

### Prerequisites
- AWS Account with IAM user
- GitHub Account
- Node.js >= 20
- Docker Desktop
- Terraform >= 1.5
- AWS CLI >= 2

### Step 1 - Clone the Repository
```bash
git clone https://github.com/toyositaiwo/devops-challenge.git
cd devops-challenge
```

### Step 2 - Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output: json
```

### Step 3 - Create Terraform Backend Resources
```bash
# Create S3 bucket for state
aws s3api create-bucket --bucket devops-challenge-tf-state-137068226798 --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket devops-challenge-tf-state-137068226798 --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

### Step 4 - Deploy Infrastructure with Terraform
```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

### Step 5 - Build and Push Docker Image to ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 137068226798.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t devops-challenge-prod ./app

# Tag image
docker tag devops-challenge-prod:latest 137068226798.dkr.ecr.us-east-1.amazonaws.com/devops-challenge-prod:latest

# Push image
docker push 137068226798.dkr.ecr.us-east-1.amazonaws.com/devops-challenge-prod:latest
```

### Step 6 - Deploy to ECS
```bash
aws ecs update-service \
  --cluster devops-challenge-prod-cluster \
  --service devops-challenge-prod-service \
  --force-new-deployment \
  --region us-east-1
```

### Step 7 - Add GitHub Secrets for CI/CD
Go to GitHub repo Settings -> Secrets -> Actions and add:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

### Step 8 - Verify Deployment
```bash
curl http://devops-challenge-prod-alb-1796929751.us-east-1.elb.amazonaws.com/health
# Expected: {"status":"healthy","timestamp":"...","uptime":...}
```

---

## CI/CD Pipeline

The pipeline at `.github/workflows/ci-cd.yml` runs automatically on every push to main.

### On Pull Request to main:
| Job | What it does |
|-----|-------------|
| Test | Runs Jest tests, uploads coverage report |
| Terraform Plan | Shows infrastructure changes as PR comment |

### On Push to main:
| Job | What it does |
|-----|-------------|
| Test | Runs Jest tests |
| Build & Push | Builds Docker image, tags with run number and git SHA, pushes to ECR |
| Terraform Apply | Provisions or updates AWS infrastructure |
| Deploy | Updates ECS service with new image |
| Health Check | Verifies app is responding with 200 OK |

### Image Tagging Strategy
Every image gets two tags:
- `{run_number}-{git_sha}` - unique, traceable to exact commit
- `latest` - always points to most recent build

---

## Monitoring

### View Live Logs
```bash
aws logs tail /ecs/devops-challenge-prod --follow
```

### CloudWatch Dashboard
https://console.aws.amazon.com/cloudwatch/home#dashboards:name=devops-challenge-prod

### Alarms Configured
| Alarm | Threshold |
|-------|-----------|
| ALB 5xx Errors | More than 10 per minute |
| ECS CPU High | Above 85% for 3 periods |
| ECS Memory High | Above 85% for 3 periods |

### Auto Scaling
| Metric | Target |
|--------|--------|
| CPU Utilization | 70% |
| Memory Utilization | 80% |
| Min Tasks | 1 |
| Max Tasks | 4 |

---

## Design Decisions

### Why ECS Fargate over EC2?
No EC2 instances to patch or manage. Fargate scales tasks individually and charges only for what is used. This reduces operational overhead significantly.

### Why ECS over EKS?
Kubernetes adds complexity that is not justified for a single service. ECS is simpler, cheaper, and fully sufficient for this workload.

### Why Modular Terraform?
Each module (vpc, ecr, ecs, cloudwatch) is independently reusable across environments. The environments/prod folder is a thin composition layer that wires modules together. This makes it easy to add staging or dev environments later.

### Why Private Subnets for ECS Tasks?
ECS tasks are not directly accessible from the internet. All traffic flows through the ALB which acts as the single entry point. This improves security significantly.

### Why GitHub Actions over Jenkins?
GitHub Actions requires no additional infrastructure. It is tightly integrated with the GitHub repository and supports all required features out of the box.

### Why Multi-Stage Dockerfile?
The final production image contains only the application code and production dependencies. Build tools and dev dependencies are excluded, resulting in a smaller and more secure image.

---

## Assumptions Made

1. AWS account exists with billing enabled
2. Single region deployment is sufficient (us-east-1)
3. HTTP only is acceptable - HTTPS not required for this challenge
4. A single NAT Gateway is used to reduce cost (one per AZ would be used in full production)
5. GitHub Secrets are used for AWS credentials instead of OIDC for simplicity

---

## Limitations and Improvements

| Current Limitation | Suggested Improvement |
|-------------------|----------------------|
| HTTP only | Add ACM certificate and HTTPS listener on ALB |
| Single region | Add Route53 with multi-region failover |
| No custom domain | Purchase domain and configure Route53 |
| Single NAT Gateway | Use one NAT per AZ to avoid cross-AZ charges |
| No secrets manager | Use AWS Secrets Manager for app secrets |
| Long-lived AWS keys | Use GitHub OIDC provider to eliminate static credentials |
| No staging environment | Add staging environment using same Terraform modules |
| Basic alerting | Integrate CloudWatch alarms with SNS and PagerDuty |

---

## API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| / | GET | App info | 200 - App name, version, environment |
| /health | GET | Health check for ALB | 200 - Status, timestamp, uptime |
| /info | GET | Detailed app info | 200 - App, node version, platform |

---

## Author
Taiwo Akintolu
GitHub: https://github.com/toyositaiwo