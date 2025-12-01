# **✅ Centralized Logging & Monitoring System (CloudWatch + Lambda + S3 + SNS)**

```md
# 📊 Centralized Logging & Monitoring System on AWS  
A production-ready monitoring system built using **CloudWatch, Lambda, S3, SNS, and IAM** to collect, analyze, alert, and archive logs from multiple EC2/application servers.

---

# 🏗️ Architecture Diagram

```

```
                     +----------------------------+
                     |        CloudWatch          |
                     |    Dashboards / Alarms     |
                     +-------------+--------------+
                                   |
                                   |
                       +-----------v------------+
                       |   CloudWatch Metrics   |
                       |  (CPU, Memory, Disk)   |
                       +-----------+------------+
                                   |
                                   |
            +----------------------v-----------------------+
            |                CloudWatch Logs               |
            |  /web/logs     /app/logs     /error/logs     |
            +---------+-------------------+-----------------+
                      | CloudWatch Log Stream
                      |
                      v
            +-----------------------+
            |  Lambda Function      |
            |  (Error Filtering)    |
            +-----------+-----------+
                        |
                        | SNS Publish
                        v
           +---------------------------------+
           |          SNS Alerts             |
           | (Email / SMS for CRITICAL logs) |
           +---------------------------------+

                       Log Archival (30 days)
                       ----------------------->
                                    +--------+
                                    |  S3     |
                                    | Archive |
                                    +--------+

            +---------------------------------------------+
            |                 EC2 Servers                 |
            | CloudWatch Agent → Logs + Metrics to CW     |
            +---------------------------------------------+
```

````

---

# 🚀 Project Overview

This project implements a **centralized logging and monitoring system** for EC2 instances and application servers using AWS CloudWatch.  
It automatically collects logs, filters critical errors, sends real-time alerts, and archives logs for compliance.

---

# 🧰 Tech Stack

- **AWS CloudWatch**
- **AWS Lambda (Python)**
- **AWS SNS**
- **AWS S3 (log archival)**
- **IAM Roles & Policies**
- **EC2 with CloudWatch Agent**

---

# ✨ Features

### ✅ Centralized Log Collection  
CloudWatch Agent on EC2 streams:
- System logs  
- Application logs  
- Custom logs  

### ✅ Error Detection With Lambda  
Lambda parses log events for:
- `ERROR`
- `CRITICAL`
- `Exception`

And sends alerts to SNS.

### ✅ Real-Time Alerts  
SNS sends:
- Email Alerts  
- SMS Alerts (optional)

### ✅ Log Archival  
Logs automatically move to:
- **S3 Glacier after 30 days**
- Deleted after 365 days

### ✅ Custom CloudWatch Dashboards  
Includes:
- CPU
- Memory
- Disk
- Network
- Application custom metrics

### ✅ Metric Filters  
Detects:
- HTTP 500 errors  
- Application exceptions  

---

# 🛠️ Implementation Steps

## **1️⃣ Enable CloudWatch Logs & Metrics**
- Attach IAM role to EC2 with:
  - CloudWatchAgentServerPolicy  
  - AmazonSSMManagedInstanceCore  
- Install CloudWatch Agent  
- Configure log streaming to CloudWatch log groups

---

## **2️⃣ Create CloudWatch Log Groups**
Examples:
- `/production/web`
- `/production/app`
- `/production/error-logs`

---

## **3️⃣ Set Up SNS Alerts**
- Create SNS topic: `critical-error-alerts`
- Add email subscription

---

## **4️⃣ Lambda Function for Error Filtering**

### **Lambda Code**
```python
import boto3
import json

sns = boto3.client('sns')
TOPIC_ARN = "arn:aws:sns:REGION:ACCOUNT_ID:critical-error-alerts"

def lambda_handler(event, context):
    for record in event['records']:
        message = json.loads(record['message'])
        log_msg = message.get("log", "")

        if "ERROR" in log_msg or "CRITICAL" in log_msg:
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject="Critical Error Detected",
                Message=log_msg
            )
    return {"status": "success"}
````

---

## **5️⃣ Create Log Subscription Filter**

* Go to CloudWatch Log Group
* Create subscription → Lambda
* Filter pattern:

  ```
  ERROR OR CRITICAL OR Exception
  ```

---

## **6️⃣ Log Archival to S3**

* Create S3 bucket
* Add lifecycle rule:

  * Move logs to Glacier after 30 days
  * Delete logs after 1 year

---

## **7️⃣ Create Monitoring Dashboards**

Add widgets for:

* CPU Utilization
* Memory Usage
* Disk I/O
* Application Metrics
* Error counts

---

## **8️⃣ Add Metric Filters**

Example:

### HTTP 500 errors:

Filter:

```
500
```

Metric name: `Http500Errors`

Create alarm → Notify SNS.

---

# 📦 Folder Structure Example

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

# 🧑‍💻 Author

**Venkata Lingarao Andugulapati**
GitHub: [https://github.com/VLingarao](https://github.com/VLingarao)

Portfolio: [https://venkata-lingarao-portfolio.netlify.app](https://venkata-lingarao-portfolio.netlify.app)
