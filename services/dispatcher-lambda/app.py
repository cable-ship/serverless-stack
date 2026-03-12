import json
import os
import uuid
from datetime import datetime

import boto3

dynamodb = boto3.resource("dynamodb")
ecs = boto3.client("ecs")


def _apigw_response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def write_to_dynamodb(message: dict) -> None:
    table = dynamodb.Table(os.environ["TABLE_NAME"])
    table.put_item(
        Item={
            "request_id": str(uuid.uuid4()),
            "timestamp": datetime.utcnow().isoformat(),
            "region": message.get("region", "unknown"),
            "event_type": message.get("type"),
            "email": message.get("email", ""),
        }
    )


def run_ecs_task(message: dict) -> dict:
    subnet_ids = json.loads(os.environ["SUBNET_IDS"])
    security_group_ids = json.loads(os.environ.get("SECURITY_GROUP_IDS", "[]"))

    awsvpc_config = {
        "subnets": subnet_ids,
        "assignPublicIp": "ENABLED",
    }
    if security_group_ids:
        awsvpc_config["securityGroups"] = security_group_ids

    container_name = os.environ.get("CONTAINER_NAME", "event-processor")
    return ecs.run_task(
        cluster=os.environ["CLUSTER_NAME"],
        taskDefinition=os.environ["TASK_DEF_ARN"],
        launchType="FARGATE",
        overrides={
            "containerOverrides": [
                {
                    "name": container_name,
                    "environment": [
                        {"name": "EVENT_TYPE", "value": message.get("type", "")},
                        {"name": "EVENT_REGION", "value": message.get("region", "")},
                        {"name": "EVENT_EMAIL", "value": message.get("email", "")},
                    ],
                }
            ]
        },
        networkConfiguration={
            "awsvpcConfiguration": awsvpc_config,
        },
    )


def handler(event, context):
    region = os.environ.get("AWS_REGION", "unknown")

    # Direct API Gateway call — build a synthetic USER_GREETED event
    if "Records" not in event:
        message = {
            "type": "USER_GREETED",
            "region": region,
            "email": os.environ.get("USER_EMAIL", ""),
            "repo": os.environ.get("REPO_URL", ""),
        }
        write_to_dynamodb(message)
        sdk_resp = run_ecs_task(message)
        return _apigw_response(
            200,
            {"processed": 1, "region": region, "trigger": "api-gateway", "ecs": sdk_resp},
        )

    # SNS subscription trigger
    for record in event["Records"]:
        message = json.loads(record["Sns"]["Message"])
        if message.get("type") == "USER_GREETED":
            write_to_dynamodb(message)
            run_ecs_task(message)
    return {"processed": "sns"}
