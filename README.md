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

# 🎯 Business Value

* Faster incident detection (MTTR ↓)
* Single pane of observability
* Automated production alerting
* Secure long-term log retention
* SRE-level monitoring for any application

---

# 🧑‍💻 Author

**Venkata Lingarao Andugulapati**

GitHub: [https://github.com/VLingarao](https://github.com/VLingarao)
Portfolio: [https://venkata-lingarao-portfolio.netlify.app](https://venkata-lingarao-portfolio.netlify.app)
