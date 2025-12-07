# 📊 Centralized Logging & Monitoring System (AWS CloudWatch + Lambda + S3 + SNS)

A production-ready **centralized monitoring and alerting system** built on AWS using  
**CloudWatch, Lambda (Python), SNS, S3, and IAM** to collect logs, detect failures, send alerts, and archive logs from multiple EC2/application servers.

# 🏗️ Architecture Diagram


```
                         +-----------------------------------+
                         |          CloudWatch Dashboard      |
                         |   (CPU, Memory, Disk, Metrics)     |
                         +----------------+--------------------+
                                          |
                                          |
                             +------------v-------------+
                             |     CloudWatch Metrics   |
                             |  (System & App Metrics)  |
                             +------------+-------------+
                                          |
                                          |
                    +---------------------v-----------------------+
                    |                CloudWatch Logs              |
                    |  /web/logs   /app/logs   /error/logs        |
                    +--------+------------------------+-----------+
                             |   Log Stream Event
                             |
                             v
                    +-------------------------+
                    |      Lambda Function    |
                    |  (Error Log Filtering)  |
                    +------------+------------+
                                 |
                                 | SNS Publish
                                 v
                   +--------------------------------------+
                   |               SNS Alerts             |
                   |  (Email / SMS for CRITICAL errors)   |
                   +--------------------------------------+

                              Log Archival → 30 Days
                              -------------------------->
                                            +-------+
                                            |  S3   |
                                            |Archive|
                                            +-------+

                    +--------------------------------------------------+
                    |                    EC2 Servers                   |
                    | CloudWatch Agent → Send Logs & Metrics to CW     |
                    +--------------------------------------------------+
```



# 🚀 Overview

This project implements a **centralized, automated, real-time logging and monitoring platform** for AWS EC2 and applications.  
It detects application issues instantly, sends alerts, and stores logs long-term in S3.


# 🧰 Tech Stack

- **AWS CloudWatch Logs & Metrics**
- **AWS Lambda (Python 3.9)**
- **AWS SNS (Email/SMS Alerts)**
- **AWS S3 (Archival & Compliance)**
- **IAM Roles & Permissions**
- **CloudWatch Agent on EC2**

---

# 📝 Prerequisites

- EC2 instance running Amazon Linux 2 / Ubuntu
- CloudWatch Agent installed
- IAM instance role attached with:
  - `CloudWatchAgentServerPolicy`
  - `AmazonSSMManagedInstanceCore`
- Lambda role with:
  - `AWSLambdaBasicExecutionRole`
  - `AmazonSNSFullAccess`
  - `CloudWatchReadOnlyAccess`

---

# ✨ Features

### ✅ Centralized Log Collection
- Application logs  
- System logs  
- Custom logs  
- Real-time log streaming via CloudWatch Agent  

### ✅ Automated Error Detection
Lambda detects:
- `ERROR`
- `CRITICAL`
- `Exception`

### ✅ Real-Time Alerts (SNS)
Alerts delivered via:
- Email  
- SMS (optional)

### ✅ Log Archival & Retention
- Move logs to Glacier after **30 days**
- Delete logs after **365 days**

### ✅ CloudWatch Dashboards
Dashboards include:
- CPU
- Memory
- Disk I/O
- Network
- App-specific metrics

### ✅ Metric Filters
Detect:
- HTTP 500 errors
- Application exceptions

---

# 🛠️ Implementation Steps (AWS Console)

## **1️⃣ Install & Configure CloudWatch Agent**
SSH into EC2 and install CloudWatch Agent.

Create CloudWatch Agent config file:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/production/system"
          },
          {
            "file_path": "/var/log/app/app.log",
            "log_group_name": "/production/app"
          }
        ]
      }
    }
  }
}
````

Start agent:

```
sudo systemctl start amazon-cloudwatch-agent
```

---

## **2️⃣ Create CloudWatch Log Groups**

Example log groups:

* `/production/system`
* `/production/app`
* `/production/error`

---

## **3️⃣ Create SNS Topic**

Topic name:

```
critical-error-alerts
```

Add email subscription.

---

## **4️⃣ Lambda for Error Filtering**

File: `lambda/error-processor.py`

```python
import boto3
import json

sns = boto3.client("sns")
TOPIC_ARN = "arn:aws:sns:REGION:ACCOUNT_ID:critical-error-alerts"

def lambda_handler(event, context):
    for record in event["records"]:
        msg = json.loads(record["message"])
        log = msg.get("log", "")

        if "ERROR" in log or "CRITICAL" in log or "Exception" in log:
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject="🔥 Critical Application Error Detected!",
                Message=log
            )

    return {
        "statusCode": 200,
        "body": json.dumps("Processed logs successfully")
    }
```

---

## **5️⃣ Create Log Subscription Filter**

CloudWatch → Log Group → Subscription filter → Lambda

Filter pattern:

```
ERROR OR CRITICAL OR Exception
```

---

## **6️⃣ Create S3 Log Archival Bucket**

Create lifecycle rule:

* Move to Glacier → **after 30 days**
* Delete → **after 365 days**

---

## **7️⃣ Create CloudWatch Dashboard**

Add widgets for:

* CPUUtilization
* DiskReadOps
* NetworkIn
* Custom error metric
* Log insights queries

---

## **8️⃣ Add Metric Filters**

Example HTTP 500 detector:

Filter pattern:

```
500
```

Assign metric name:

```
Http500Errors
```

Create alarm → SNS alert.

---

# 📂 Folder Structure

```
centralized-logging/
│
├── lambda/
│   └── error-processor.py
│
├── cloudwatch-agent/
│   └── cw-config.json
│
└── README.md
```

---

   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
[ec2-user@ip-172-31-0-229 ~]$ sudo yum install amazon-cloudwatch-agent -y
Amazon Linux 2023 Kernel Livepatch repository                                                                      289 kB/s |  29 kB     00:00    
Dependencies resolved.
===================================================================================================================================================
 Package                                   Architecture             Version                                    Repository                     Size
===================================================================================================================================================
Installing:
 amazon-cloudwatch-agent                   x86_64                   1.300060.1-1.amzn2023                      amazonlinux                    79 M

Transaction Summary
===================================================================================================================================================
Install  1 Package

Total download size: 79 M
Installed size: 238 M
Downloading Packages:
amazon-cloudwatch-agent-1.300060.1-1.amzn2023.x86_64.rpm                                                            70 MB/s |  79 MB     00:01    
---------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                               69 MB/s |  79 MB     00:01     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                           1/1 
  Running scriptlet: amazon-cloudwatch-agent-1.300060.1-1.amzn2023.x86_64                                                                      1/1 
create group cwagent, result: 0
create user cwagent, result: 0

  Installing       : amazon-cloudwatch-agent-1.300060.1-1.amzn2023.x86_64                                                                      1/1 
  Running scriptlet: amazon-cloudwatch-agent-1.300060.1-1.amzn2023.x86_64                                                                      1/1 
  Verifying        : amazon-cloudwatch-agent-1.300060.1-1.amzn2023.x86_64                                                                      1/1 

Installed:
  amazon-cloudwatch-agent-1.300060.1-1.amzn2023.x86_64                                                                                             

Complete!
[ec2-user@ip-172-31-0-229 ~]$ sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
2025/12/03 10:13:11 Starting config-wizard, this will map back to a call to amazon-cloudwatch-agent
2025/12/03 10:13:11 Executing /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent with arguments: [config-wizard]
================================================================
= Welcome to the Amazon CloudWatch Agent Configuration Manager =
=                                                              =
= CloudWatch Agent allows you to collect metrics and logs from =
= your host and send them to CloudWatch. Additional CloudWatch =
= charges may apply.                                           =
================================================================
On which OS are you planning to use the agent?
1. linux
2. windows
3. darwin
default choice: [1]:
1
Trying to fetch the default region based on ec2 metadata...
I! imds retry client will retry 1 timesAre you using EC2 or On-Premises hosts?
1. EC2
2. On-Premises
default choice: [1]:
1
Which user are you planning to run the agent?
1. cwagent
2. root
3. others
default choice: [1]:
2
Do you want to turn on StatsD daemon?
1. yes
2. no
default choice: [1]:
2
Do you want to monitor metrics from CollectD? WARNING: CollectD must be installed or the Agent will fail to start
1. yes
2. no
default choice: [1]:
2
Do you want to monitor any host metrics? e.g. CPU, memory, etc.
1. yes
2. no
default choice: [1]:
1
Do you want to monitor cpu metrics per core?
1. yes
2. no
default choice: [1]:
1
Do you want to add ec2 dimensions (ImageId, InstanceId, InstanceType, AutoScalingGroupName) into all of your metrics if the info is available?
1. yes
2. no
default choice: [1]:
1
Do you want to aggregate ec2 dimensions (InstanceId)?
1. yes
2. no
default choice: [1]:
1
Would you like to collect your metrics at high resolution (sub-minute resolution)? This enables sub-minute resolution for all metrics, but you can customize for specific metrics in the output json file.
1. 1s
2. 10s
3. 30s
4. 60s
default choice: [4]:
4
Which default metrics config do you want?
1. Basic
2. Standard
3. Advanced
4. None
default choice: [1]:
2
Current config as follows:
{
        "agent": {
                "metrics_collection_interval": 60,
                "run_as_user": "root"
        },
        "metrics": {
                "aggregation_dimensions": [
                        [
                                "InstanceId"
                        ]
                ],
                "append_dimensions": {
                        "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                        "ImageId": "${aws:ImageId}",
                        "InstanceId": "${aws:InstanceId}",
                        "InstanceType": "${aws:InstanceType}"
                },
                "metrics_collected": {
                        "cpu": {
                                "measurement": [
                                        "cpu_usage_idle",
                                        "cpu_usage_iowait",
                                        "cpu_usage_user",
                                        "cpu_usage_system"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ],
                                "totalcpu": false
                        },
                        "disk": {
                                "measurement": [
                                        "used_percent",
                                        "inodes_free"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "diskio": {
                                "measurement": [
                                        "io_time"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "mem": {
                                "measurement": [
                                        "mem_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        },
                        "swap": {
                                "measurement": [
                                        "swap_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        }
                }
        }
}
Are you satisfied with the above config? Note: it can be manually customized after the wizard completes to add additional items.
1. yes
2. no
default choice: [1]:
1
Do you have any existing CloudWatch Log Agent (http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AgentReference.html) configuration file to import for migration?
1. yes
2. no
default choice: [2]:
2
Do you want to monitor any log files?
1. yes
2. no
default choice: [1]:
1
Log file path:
/var/log/messages
Log group name:
default choice: [messages]
ec2-system-logs
Log group class:
1. STANDARD
2. INFREQUENT_ACCESS
default choice: [1]:
1
Log stream name:
default choice: [{instance_id}]

Log Group Retention in days
1. -1
2. 1
3. 3
4. 5
5. 7
6. 14
7. 30
8. 60
9. 90
10. 120
11. 150
12. 180
13. 365
14. 400
15. 545
16. 731
17. 1096
18. 1827
19. 2192
20. 2557
21. 2922
22. 3288
23. 3653
default choice: [1]:
7
Do you want to specify any additional log files to monitor?
1. yes
2. no
default choice: [1]:
2
Do you want the CloudWatch agent to also retrieve X-ray traces?
1. yes
2. no
default choice: [1]:
2
Existing config JSON identified and copied to:  /opt/aws/amazon-cloudwatch-agent/etc/backup-configs
Saved config file to /opt/aws/amazon-cloudwatch-agent/bin/config.json successfully.
Current config as follows:
{
        "agent": {
                "metrics_collection_interval": 60,
                "run_as_user": "root"
        },
        "logs": {
                "logs_collected": {
                        "files": {
                                "collect_list": [
                                        {
                                                "file_path": "/var/log/messages",
                                                "log_group_class": "STANDARD",
                                                "log_group_name": "ec2-system-logs",
                                                "log_stream_name": "{instance_id}",
                                                "retention_in_days": 30
                                        }
                                ]
                        }
                }
        },
        "metrics": {
                "aggregation_dimensions": [
                        [
                                "InstanceId"
                        ]
                ],
                "append_dimensions": {
                        "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                        "ImageId": "${aws:ImageId}",
                        "InstanceId": "${aws:InstanceId}",
                        "InstanceType": "${aws:InstanceType}"
                },
                "metrics_collected": {
                        "cpu": {
                                "measurement": [
                                        "cpu_usage_idle",
                                        "cpu_usage_iowait",
                                        "cpu_usage_user",
                                        "cpu_usage_system"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ],
                                "totalcpu": false
                        },
                        "disk": {
                                "measurement": [
                                        "used_percent",
                                        "inodes_free"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "diskio": {
                                "measurement": [
                                        "io_time"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "mem": {
                                "measurement": [
                                        "mem_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        },
                        "swap": {
                                "measurement": [
                                        "swap_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        }
                }
        }
}
Please check the above content of the config.
The config file is also located at /opt/aws/amazon-cloudwatch-agent/bin/config.json.
Edit it manually if needed.
Do you want to store the config in the SSM parameter store?
1. yes
2. no
default choice: [1]:
2
Program exits now.
[ec2-user@ip-172-31-0-229 ~]$ 

---

# 🧑‍💻 Author

**Venkata Lingarao Andugulapati**

GitHub: [https://github.com/VLingarao](https://github.com/VLingarao)
Portfolio: [https://venkata-lingarao-portfolio.netlify.app](https://venkata-lingarao-portfolio.netlify.app)
