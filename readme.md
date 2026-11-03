\# AWS EC2 Node.js Monitoring \& Alerting with Terraform



\## Project Overview



This project provisions an AWS EC2 instance running a Node.js application and implements end-to-end monitoring and alerting using Amazon CloudWatch.



Infrastructure is managed using Terraform, with separate configuration files organized by AWS service.



\### AWS Architecture



```text

&#x20;                User / HTTP Client

&#x20;                        |

&#x20;                        v

&#x20;                EC2 Ubuntu Instance

&#x20;                        |

&#x20;                 Node.js Application

&#x20;                   Port 3000

&#x20;                        |

&#x20;             +----------+----------+

&#x20;             |                     |

&#x20;             v                     v

&#x20;       CloudWatch Agent       Application Logs

&#x20;             |

&#x20;             v

&#x20;       Amazon CloudWatch

&#x20;             |

&#x20;      +------+------+------+

&#x20;      |             |      |

&#x20;      v             v      v

&#x20;     CPU          Memory   Disk

&#x20;      |

&#x20;      v

&#x20; CloudWatch Alarms

&#x20;      |

&#x20;  +---+------+

&#x20;  |          |

&#x20;  v          v

&#x20; SNS      EventBridge

&#x20;Email     Alarm Events

```



\## Infrastructure Details



| Resource | Configuration |

|---|---|

| AWS Region | ap-south-1 |

| EC2 Instance | t2.micro |

| Instance ID | i-070a41870fbcb35d5 |

| Public IP | 15.206.169.69 |

| Application Port | 3000 |

| Dashboard | node-monitoring-dashboard |

| Application Log Group | /aws/ec2/node-monitoring/app |

| Event Log Group | /aws/events/node-monitoring-alarms |

| SNS Topic | node-monitoring-alerts |



\## Application Endpoints



| Endpoint | Purpose |

|---|---|

| `/health` | Application health check |

| `/error` | Generates an application error for testing |

| `/stress` | Generates CPU load for alarm testing |



\## CloudWatch Monitoring



\### Metrics monitored



\- EC2 CPU utilization

\- Memory utilization through CloudWatch Agent

\- Disk utilization through CloudWatch Agent

\- Application errors through a CloudWatch metric filter



\### CloudWatch Alarms



\*\*CPU Alarm\*\*

\- Metric: CPUUtilization

\- Namespace: AWS/EC2

\- Threshold: Greater than 70%

\- Period: 60 seconds

\- Evaluation periods: 1



\*\*Application Error Alarm\*\*

\- Metric: ErrorCount

\- Namespace: Application/NodeApp

\- Threshold: Greater than 3

\- Period: 300 seconds



Both alarms are configured to send SNS notifications.



\### CloudWatch Dashboard



Dashboard name: `node-monitoring-dashboard`



Four widgets:

1\. EC2 CPU Utilization

2\. Memory Utilization

3\. Disk Utilization

4\. Application Error Count



The root disk metric uses these dimensions:



\- InstanceId: i-070a41870fbcb35d5

\- path: /

\- device: xvda1

\- fstype: ext4



\## Testing and Verification



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



\## Terraform Commands



Run these commands from the Terraform directory:



```cmd

terraform fmt

terraform validate

terraform plan

terraform apply

```



Always review the plan before applying changes.



\## Final Verification



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



\## Important Notes



\- Infrastructure is currently deployed and intentionally left running.

\- Do not run `terraform destroy` without explicitly deciding to remove the infrastructure.

\- Review any proposed EC2 replacement or resource deletion before applying Terraform changes.

\- AWS resources can incur ongoing charges. Monitor AWS billing.



\## Skills Demonstrated



\- AWS EC2 provisioning

\- Terraform infrastructure as code

\- Terraform state management

\- Linux systemd services

\- Node.js application deployment

\- CloudWatch Agent configuration

\- CloudWatch Logs and metric filters

\- CloudWatch alarms

\- SNS notifications

\- EventBridge event routing

\- CloudWatch dashboards

\- AWS CLI troubleshooting

\- End-to-end monitoring and alert testing



