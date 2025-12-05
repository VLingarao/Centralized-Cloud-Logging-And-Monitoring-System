import json
import os
import boto3

sns = boto3.client("sns")
SNS_TOPIC = os.environ["SNS_TOPIC_ARN"]

def handler(event, context):
    for record in event["records"]:
        msg = record["message"]

        if any(x in msg for x in ["ERROR", "CRITICAL", "FAILED"]):
            sns.publish(
                TopicArn=SNS_TOPIC,
                Subject="CRITICAL ERROR ALERT",
                Message=f"Critical log detected:\n\n{msg}"
            )

    return {"status": "done"}
