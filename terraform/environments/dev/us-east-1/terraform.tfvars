region = "us-east-1"

vpc_cidr = "10.10.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets = [
  "10.10.1.0/24",
  "10.10.2.0/24",
  "10.10.3.0/24",
]

# Required app inputs
cognito_user_email  = "kmajidwork@gmail.com"           # Cognito user and event payload email
notification_email  = "kmajidwork@gmail.com"           # Receives SNS notifications
repo_url            = "https://github.com/cable-ship/serverless-stack"

# Optional: Use external SNS topic (cross-account)
external_sns_topic_arn = ""
enable_email_notifications = false  # Set to true to receive email notifications
