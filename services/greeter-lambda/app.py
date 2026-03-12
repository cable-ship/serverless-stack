import json
import os
import boto3


def handler(event, context):
    sns_client = boto3.client("sns")

    region = os.environ.get("AWS_REGION", "unknown")
    sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")
    payload_email = os.environ.get("PAYLOAD_EMAIL", "")
    repo_url = os.environ.get("REPO_URL", "")

    if not sns_topic_arn:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "SNS_TOPIC_ARN not configured"}),
        }

    message = {
        "type": "USER_GREETED",
        "region": region,
        "email": payload_email,
        "repo": repo_url,
    }

    sdk_resp = sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=json.dumps(message),
        Subject="USER_GREETED",
    )
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"region": region, "sns": sdk_resp}, default=str),
    }
