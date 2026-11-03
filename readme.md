# AWS EC2 Node.js Monitoring & Alerting with Terraform

## Project Overview

This project provisions an AWS EC2 instance running a Node.js application and implements end-to-end monitoring and alerting using Amazon CloudWatch.

Infrastructure is managed using Terraform, with separate configuration files organized by AWS service.

## AWS Architecture

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
        CloudWatch Agent       Application Logs
              |
              v
        Amazon CloudWatch
              |
       +------+------+------+
       |             |      |
       v             v      v
      CPU          Memory   Disk
       |
       v
  CloudWatch Alarms
       |
   +---+------+
   |          |
   v          v
  SNS      EventBridge
 Email     Alarm Events
```

## Infrastructure Details

| Resource | Configuration |
|---|---|
| AWS Region | ap-south-1 |
| EC2 Instance | t2.micro |
| Operating System | Ubuntu 22.04 |
| Application Port | 3000 |
| Dashboard | node-monitoring-dashboard |
| Application Log Group | /aws/ec2/node-monitoring/app |
| Event Log Group | /aws/events/node-monitoring-alarms |
| SNS Topic | node-monitoring-alerts |

## Application Endpoints

| Endpoint | Purpose |
|---|---|
| `/health` | Application health check |
| `/error` | Generates an application error for testing |
| `/stress` | Generates CPU load for alarm testing |

## CloudWatch Monitoring

### Metrics monitored

- EC2 CPU utilization
- Memory utilization through CloudWatch Agent
- Disk utilization through CloudWatch Agent
- Application errors through a CloudWatch metric filter

### CloudWatch Alarms

**CPU Alarm**

- Metric: CPUUtilization
- Namespace: AWS/EC2
- Threshold: Greater than 70%
- Period: 60 seconds
- Evaluation periods: 1

**Application Error Alarm**

- Metric: ErrorCount
- Namespace: Application/NodeApp
- Threshold: Greater than 3
- Period: 300 seconds
- Statistic: Sum

Both alarms are configured to send SNS notifications.

### EventBridge

EventBridge captures state changes for the two configured CloudWatch alarms:

- ALARM
- OK
- INSUFFICIENT_DATA

Events are forwarded to a dedicated CloudWatch Logs group. The rule is scoped to the CPU and application-error alarms rather than every alarm in the AWS account.

### CloudWatch Dashboard

Dashboard name: `node-monitoring-dashboard`

Four widgets:

1. EC2 CPU Utilization
2. Memory Utilization
3. Disk Utilization
4. Application Error Count

The root disk metric uses these dimensions:

- path: /
- device: xvda1
- fstype: ext4

## Testing and Verification

Tests completed on November 3, 2026.

| Test | Result |
|---|---|
| Application health endpoint | HTTP 200 |
| Application error endpoint | HTTP 500 |
| Application log ingestion | Successful |
| Error metric filter | Verified |
| Error alarm | Triggered |
| SNS email notification | Received |
| EventBridge alarm event | Recorded |
| CPU stress test | Successful |
| CPU alarm | Triggered and recovered |
| Memory metric | Approximately 20% |
| Disk metric | Approximately 28.05% |
| Dashboard | Four widgets configured and disk dimension corrected |

The CPU stress test produced a peak CPU datapoint of approximately 95.23%, exceeding the 70% alarm threshold. CloudWatch transitioned the alarm from OK to ALARM and subsequently back to OK when CPU utilization dropped.

## Terraform Setup

Run these commands from the `terraform` directory.

### 1. Configure variables

Copy the example variables file:

```cmd
copy terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set `alarm_email` to your email address.

The `alarm_email` variable is required. The other variables have default values and can be customized if needed.

### 2. Initialize Terraform

```cmd
terraform init
```

### 3. Format and validate

```cmd
terraform fmt
terraform validate
```

### 4. Review and deploy

```cmd
terraform plan
terraform apply
```

Always review the execution plan before applying changes, especially proposed EC2 replacements or resource deletions.

### 5. Confirm SNS subscription

After deployment, AWS SNS sends a subscription confirmation email to the configured `alarm_email` address.

Open that email and confirm the subscription. Email alerts will not work until the subscription is confirmed.

## Final Verification

Check the Terraform state:

```cmd
terraform state list
```

Check whether infrastructure matches the Terraform configuration:

```cmd
terraform plan
```

Expected result if there is no drift:

```text
No changes. Your infrastructure matches the configuration.
```

Review deployed outputs:

```cmd
terraform output
```

Verify the dashboard:

```cmd
aws cloudwatch get-dashboard --dashboard-name node-monitoring-dashboard --region ap-south-1
```

## Important Notes

- Infrastructure is currently deployed and intentionally left running.
- Do not run `terraform destroy` without explicitly deciding to remove the infrastructure.
- Review any proposed EC2 replacement or resource deletion before applying Terraform changes.
- AWS resources can incur ongoing charges. Monitor AWS billing.
- Keep `terraform.tfvars` and Terraform state files private. Do not commit credentials or sensitive configuration to GitHub.

## Skills Demonstrated

- AWS EC2 provisioning
- Terraform infrastructure as code
- Terraform state management
- Linux systemd services
- Node.js application deployment
- CloudWatch Agent configuration
- CloudWatch Logs and metric filters
- CloudWatch alarms
- SNS notifications
- EventBridge event routing
- CloudWatch dashboards
- AWS CLI troubleshooting
- End-to-end monitoring and alert testing
