#!/bin/bash
yum update -y

yum install -y amazon-cloudwatch-agent

cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/application/error-logs",
            "log_stream_name": "ec2-errors"
          }
        ]
      }
    }
  }
}
EOF

systemctl restart amazon-cloudwatch-agent
