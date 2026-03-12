[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "essential": true,
    "entryPoint": ["sh", "-c"],
    "command": [
      "MSG=$(printf '{\"email\":\"%s\",\"source\":\"ECS\",\"region\":\"%s\",\"repo\":\"%s\"}' \"$USER_EMAIL\" \"$AWS_DEFAULT_REGION\" \"$REPO_URL\") && aws sns publish --topic-arn \"$SNS_TOPIC_ARN\" --message \"$MSG\" --region \"$AWS_DEFAULT_REGION\" && echo SNS_PUBLISH_COMPLETE"
    ],
    "environment": [
      { "name": "SNS_TOPIC_ARN", "value": "${sns_topic_arn}" },
      { "name": "USER_EMAIL", "value": "${user_email}" },
      { "name": "REPO_URL", "value": "${repo_url}" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
