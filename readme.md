# AWS EC2 Node.js Monitoring & Alerting with Terraform

## Project Overview

This project provisions AWS infrastructure using Terraform to deploy a Node.js application on Amazon EC2 and implement monitoring, logging, and alerting using Amazon CloudWatch.

The infrastructure supports multiple environments through Terraform Workspaces:

- **dev** – Development environment
- **prod** – Production environment

Both environments use the same Terraform configuration, with environment-specific resource names, tags, log retention settings, and independent Terraform state.

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
| Terraform | Provisions and manages infrastructure |

## Multi-Environment Design

Terraform Workspaces are used to maintain separate development and production environments.

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

All resources supporting AWS tags receive common tags:

- Project
- Environment
- ManagedBy

A workspace guard prevents infrastructure deployment from the default workspace.

## Application Endpoints

| Endpoint | Purpose |
|---|---|
| `/health` | Application health check |
| `/error` | Generates an application error for testing |
| `/stress` | Generates CPU load for testing |

The application listens on port 3000.

## Monitoring and Alerting

### Metrics monitored

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

Dashboard names include the workspace name.

## Repository Structure

```text
node-monitoring-cloudwatch-terraform/
|
|-- README.md
|-- .gitignore
|
|-- terraform/
    |-- .gitignore
    |-- .terraform.lock.hcl
    |-- versions.tf
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
```

## Prerequisites

- Terraform 1.5 or later
- AWS CLI
- An AWS account
- AWS credentials configured locally
- An email address for SNS notifications

Configure AWS credentials using an AWS CLI profile or another supported AWS authentication method.

Example:

```cmd
aws configure --profile aws-learning-new
```

## Terraform Deployment

All Terraform commands below should be executed from the `terraform` directory.

### 1. Initialize Terraform

```cmd
terraform init
```

### 2. Create workspaces

```cmd
terraform workspace new dev
terraform workspace new prod
```

If the workspaces already exist, list them instead:

```cmd
terraform workspace list
```

### 3. Configure environment variables

Create local configuration files from the examples:

```cmd
copy dev.tfvars.example dev.tfvars
copy prod.tfvars.example prod.tfvars
```

Edit both files and configure your own values, especially `alarm_email`.

These local files are intentionally excluded from Git.

### 4. Deploy development

```cmd
terraform workspace select dev
terraform plan -var-file="dev.tfvars" -out="dev.tfplan"
terraform apply "dev.tfplan"
```

### 5. Deploy production

```cmd
terraform workspace select prod
terraform plan -var-file="prod.tfvars" -out="prod.tfplan"
terraform apply "prod.tfplan"
```

Always review the plan before applying changes. Check proposed resource replacements and deletions carefully.

### 6. Switch environments

```cmd
terraform workspace select dev
```

Or:

```cmd
terraform workspace select prod
```

List available workspaces:

```cmd
terraform workspace list
```

Each workspace maintains its own Terraform state.

## Verification

Check the active workspace:

```cmd
terraform workspace show
```

Review managed resources:

```cmd
terraform state list
```

Review outputs:

```cmd
terraform output
```

Check for configuration drift:

```cmd
terraform plan -var-file="dev.tfvars"
```

Use the corresponding variable file for the selected workspace.

Verify the application:

```cmd
curl http://<EC2_PUBLIC_IP>:3000/health
```

Verify the environment-specific dashboard:

```cmd
aws cloudwatch get-dashboard --dashboard-name node-monitoring-dev-dashboard --region ap-south-1
```

Replace `dev` with `prod` when checking production.

## SNS Email Notifications

After deployment, SNS sends a subscription confirmation email to the configured address.

Confirm the subscription through the email link before expecting notifications.

Development and production use separate SNS topics.

## Security and Cost Considerations

- Do not commit actual `.tfvars` files, Terraform state