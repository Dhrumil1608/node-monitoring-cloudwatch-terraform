# AWS EC2 Node.js Monitoring & Alerting with Terraform

## Project Overview

This project provisions AWS infrastructure using Terraform to deploy a Node.js application on Amazon EC2 and implement monitoring, logging, and alerting using Amazon CloudWatch.

The infrastructure supports separate development and production environments through Terraform Workspaces.

- **dev** – Development environment
- **prod** – Production environment

Both environments share the same Terraform configuration while maintaining independent state files, resource names, tags, and environment-specific settings.

Terraform state is stored remotely in Amazon S3 with encryption, versioning, and native S3 state locking.

## Architecture

```text
                     User / HTTP Client
                             |
                             v
                     EC2 Ubuntu Instance
                             |
                      Node.js Application
                         Port 3000
                             |
                  +----------+----------+
                  |                     |
                  v                     v
             CloudWatch Agent      Application Logs
                  |
                  v
              CloudWatch
                  |
          +-------+--------+
          |       |        |
          v       v        v
         CPU    Memory    Disk
          |
          v
     CloudWatch Alarms
          |
      +---+---------+
      |             |
      v             v
     SNS         EventBridge
    Email        Alarm Events
                     |
                     v
                CloudWatch Logs
```

## AWS Services Used

| Service | Purpose |
|---|---|
| Amazon EC2 | Hosts the Node.js application |
| Amazon VPC | Provides network isolation |
| IAM | Grants EC2 access to monitoring and SSM |
| CloudWatch Agent | Collects memory, disk, and log metrics |
| CloudWatch Logs | Stores application and system logs |
| CloudWatch Alarms | Monitors CPU and application errors |
| CloudWatch Dashboard | Displays monitoring metrics |
| Amazon SNS | Sends alarm notifications through email |
| Amazon EventBridge | Routes CloudWatch alarm state changes |
| Amazon S3 | Stores Terraform remote state |
| Terraform | Provisions and manages infrastructure |

## Multi-Environment Design

Terraform Workspaces maintain separate development and production environments.

| Configuration | Dev | Prod |
|---|---|---|
| Workspace | dev | prod |
| EC2 instance type | t2.micro | t2.micro |
| Application log retention | 7 days | 30 days |
| Event log retention | 7 days | 90 days |
| Resource naming | -dev | -prod |
| Environment tag | dev | prod |

Resource names are generated dynamically using the active Terraform workspace.

Examples:

- `node-monitoring-dev-dashboard`
- `node-monitoring-prod-dashboard`
- `node-monitoring-dev-alerts`
- `node-monitoring-prod-alerts`

All supported resources receive common tags:

- Project
- Environment
- ManagedBy

A Terraform workspace guard prevents deployment from the default workspace and ensures that the configured environment matches the selected workspace.

## Application Endpoints

The Node.js application listens on port 3000.

| Endpoint | Purpose |
|---|---|
| `/health` | Application health check |
| `/error` | Generates an application error for testing |
| `/stress` | Generates CPU load for testing |

## Monitoring and Alerting

### Metrics Monitored

- EC2 CPU utilization
- Memory utilization through CloudWatch Agent
- Disk utilization through CloudWatch Agent
- Application errors through a CloudWatch Logs metric filter

### CloudWatch Alarms

**CPU Alarm**

- Metric: CPUUtilization
- Namespace: AWS/EC2
- Threshold: Greater than 70%
- Period: 60 seconds
- Evaluation periods: 1

**Application Error Alarm**

- Metric: ErrorCount
- Namespace: Application/NodeApp/<environment>
- Threshold: Greater than 3
- Period: 300 seconds
- Statistic: Sum

Both alarms publish notifications to the environment-specific SNS topic.

### EventBridge

EventBridge captures state changes for the configured CPU and application-error alarms:

- ALARM
- OK
- INSUFFICIENT_DATA

Events are forwarded to an environment-specific CloudWatch Logs group.

### CloudWatch Dashboard

Each environment has its own dashboard containing four widgets:

1. EC2 CPU utilization
2. Memory utilization
3. Disk utilization
4. Application error count

Dashboard names include the active workspace name.

## Terraform Remote State Backend

This project uses an Amazon S3 backend to store Terraform state remotely.

### Backend Features

- Remote Terraform state storage in S3
- Server-side encryption
- S3 bucket versioning
- Native S3 state locking using `use_lockfile`
- Separate state files for dev and prod workspaces

The backend configuration is maintained separately from the Terraform provider configuration.

### Workspace State Structure

With the configured workspace key prefix, the state files follow this structure:

```text
S3 Bucket
|
|-- node-monitoring/
|   |-- terraform.tfstate
|
|-- workspaces/
    |
    |-- dev/
    |   |-- node-monitoring/
    |       |-- terraform.tfstate
    |
    |-- prod/
        |-- node-monitoring/
            |-- terraform.tfstate
```

The default workspace state path is shown for completeness. The dev and prod workspaces use their respective remote state paths.

## Repository Structure

```text
node-monitoring-cloudwatch-terraform/
|
|-- README.md
|-- .gitignore
|
|-- terraform/
    |
    |-- .gitignore
    |-- .terraform.lock.hcl
    |-- versions.tf
    |-- backend.tf
    |-- providers.tf
    |-- variables.tf
    |-- locals.tf
    |-- workspace_guard.tf
    |-- network.tf
    |-- ec2.tf
    |-- iam.tf
    |-- cloudwatch_logs.tf
    |-- cloudwatch_alarms.tf
    |-- dashboard.tf
    |-- eventbridge.tf
    |-- sns.tf
    |-- outputs.tf
    |-- user_data.sh.tftpl
    |-- cloudwatch-agent-config.json.tftpl
    |-- dev.tfvars.example
    |-- prod.tfvars.example
    |-- backend.hcl (local, not committed)
```

## Prerequisites

Before deploying this project, ensure you have:

- An AWS account
- Terraform 1.5 or later
- AWS CLI installed
- AWS credentials configured locally
- An S3 bucket for Terraform remote state
- An email address for SNS notifications

### Configure AWS CLI

Create an AWS CLI profile:

```cmd
aws configure --profile your-aws-profile
```

Verify the configured identity:

```cmd
aws sts get-caller-identity --profile your-aws-profile
```

The AWS account ID returned by this command must match the `allowed_account_id` value configured in your environment variable file.

The AWS identity must have permissions to:

- Manage the infrastructure resources used by this project
- Access the Terraform state bucket
- Read and write Terraform state
- Acquire and release S3 state locks

## S3 Backend Setup

The S3 bucket must exist before Terraform initializes the backend.

Create a uniquely named S3 bucket in your selected AWS region.

Configure the bucket with:

- Block all public access
- Enable bucket versioning
- Enable default server-side encryption
- Configure native S3 state locking through `use_lockfile = true` in `backend.hcl`

The AWS profile used by Terraform must have the necessary S3 permissions.

### Create Local Backend Configuration

Inside the `terraform` directory, create a file named `backend.hcl`.

Example:

```hcl
bucket               = "your-unique-terraform-state-bucket"
key                  = "node-monitoring/terraform.tfstate"
region               = "ap-south-1"
profile              = "your-aws-profile"
encrypt              = true
use_lockfile         = true
workspace_key_prefix = "workspaces"
```

Replace the example values with your own bucket name, AWS region, and profile.

**Important:**

- Do not commit `backend.hcl`.
- The file is excluded through `.gitignore`.
- Do not store AWS access keys or secret keys in this file.
- The backend bucket should be created and secured independently of the infrastructure managed by this Terraform configuration.

### Initialize Terraform

For a fresh deployment:

```cmd
terraform init -backend-config="backend.hcl"
```

If migrating an existing local Terraform state to S3:

```cmd
terraform init -migrate-state -backend-config="backend.hcl"
```

Terraform may ask for confirmation to migrate state. Review the prompt carefully before proceeding.

When migrating a project with multiple workspaces, ensure that all existing workspace states are accounted for.

## Terraform Deployment

All Terraform commands below should be executed from the `terraform` directory.

### 1. Initialize Terraform

```cmd
terraform init -backend-config="backend.hcl"
```

This initializes the required providers and configures the S3 remote backend.

If the backend has already been initialized and configured, Terraform does not need to be reinitialized for every deployment.

### 2. Create Terraform Workspaces

For a fresh deployment:

```cmd
terraform workspace new dev
terraform workspace new prod
```

If the workspaces already exist, list them:

```cmd
terraform workspace list
```

Select the required workspace:

```cmd
terraform workspace select dev
```

**Note:** Do not create duplicate workspaces. Existing workspaces should be selected.

### 3. Configure Environment Variables

Create local configuration files from the example files:

```cmd
copy dev.tfvars.example dev.tfvars
copy prod.tfvars.example prod.tfvars
```

Edit both files and configure the following values:

- AWS region
- Project name
- EC2 instance type
- SNS notification email
- Application log retention
- Event log retention
- AWS CLI profile
- Allowed AWS account ID
- Environment name

Example development configuration:

```hcl
aws_region               = "ap-south-1"
project_name             = "node-monitoring"
instance_type            = "t2.micro"
alarm_email              = "your-email@example.com"
app_log_retention_days   = 7
event_log_retention_days = 7
aws_profile              = "your-aws-profile"
allowed_account_id       = "123456789012"
environment              = "dev"
```

For production, use the production example file and set:

```hcl
environment = "prod"
```

Use your actual 12-digit AWS account ID and configured AWS CLI profile.

The `.tfvars` files are intentionally excluded from Git.

### 4. Deploy Development

Select the dev workspace:

```cmd
terraform workspace select dev
```

Verify the workspace:

```cmd
terraform workspace show
```

Review the execution plan:

```cmd
terraform plan -var-file="dev.tfvars"
```

Apply the reviewed configuration:

```cmd
terraform apply -var-file="dev.tfvars"
```

Review the proposed changes and confirm the operation when satisfied.

### 5. Deploy Production

Select the prod workspace:

```cmd
terraform workspace select prod
```

Verify the workspace:

```cmd
terraform workspace show
```

Review the execution plan:

```cmd
terraform plan -var-file="prod.tfvars"
```

Apply the reviewed configuration:

```cmd
terraform apply -var-file="prod.tfvars"
```

Always review the plan before applying changes. Pay particular attention to resource replacements and deletions.

### 6. Switch Between Environments

Select development:

```cmd
terraform workspace select dev
```

Select production:

```cmd
terraform workspace select prod
```

List available workspaces:

```cmd
terraform workspace list
```

Each workspace maintains a separate Terraform state file in the S3 backend.

## Verification

### Verify Active Workspace

```cmd
terraform workspace show
```

### List Managed Resources

```cmd
terraform state list
```

### View Terraform Outputs

```cmd
terraform output
```

### Validate Terraform Configuration

```cmd
terraform fmt -recursive
terraform validate
```

### Check Infrastructure Drift

For development:

```cmd
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
```

For production:

```cmd
terraform workspace select prod
terraform plan -var-file="prod.tfvars"
```

A clean plan should report:

```text
No changes. Your infrastructure matches the configuration.
```

### Verify Application Health

Use the public IP address of the relevant EC2 instance:

```cmd
curl http://<EC2_PUBLIC_IP>:3000/health
```

### Verify CloudWatch Dashboard

Development:

```cmd
aws cloudwatch get-dashboard --dashboard-name node-monitoring-dev-dashboard --region ap-south-1 --profile your-aws-profile
```

Production:

```cmd
aws cloudwatch get-dashboard --dashboard-name node-monitoring-prod-dashboard --region ap-south-1 --profile your-aws-profile
```

## SNS Email Notifications

The project creates separate SNS topics for development and production.

After deployment:

1. SNS sends a subscription confirmation email to the configured address.
2. Open the email.
3. Select the confirmation link.
4. Verify that the subscription is confirmed.

Email confirmation is required before SNS can deliver notifications to that email endpoint.

## Security and Cost Considerations

### Security

- Do not commit actual `.tfvars` files.
- Do not commit AWS credentials or secret keys.
- Do not commit Terraform state files or local state backups.
- Do not commit the local `backend.hcl` file.
- Keep S3 Block Public Access enabled.
- Enable S3 bucket versioning and encryption.
- Use IAM permissions following the principle of least privilege.
- Use `allowed_account_id` to prevent deployment to an unintended AWS account.
- Use the workspace guard to prevent deployment from the default workspace.
- Review Terraform plans before applying infrastructure changes.

### Cost Considerations

AWS resources may incur charges even when they are not actively being used.

Potential costs include:

- EC2 instances
- EBS volumes
- S3 storage and requests
- CloudWatch Logs ingestion and retention
- CloudWatch alarms and dashboards
- SNS notifications

Monitor AWS billing and usage regularly.

## Project Goals and Learning Outcomes

This project demonstrates practical experience with:

- Infrastructure as Code using Terraform
- Terraform workspaces for multi-environment deployments
- S3 remote state management
- Native S3 state locking
- AWS provider configuration and account safeguards
- VPC and EC2 provisioning
- IAM roles and instance profiles
- CloudWatch metrics, logs, dashboards, and alarms
- SNS email notifications
- EventBridge event routing
- Terraform variables, locals, templates, and outputs
- Git and GitHub version control
