{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBWrite",
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem"],
      "Resource": ["${table_arn}"]
    },
    {
      "Sid": "ECSRunTask",
      "Effect": "Allow",
      "Action": ["ecs:RunTask"],
      "Resource": ["*"]
    },
    {
      "Sid": "PassRole",
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": ["*"]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": ["arn:aws:logs:*:*:*"]
    }
  ]
}
