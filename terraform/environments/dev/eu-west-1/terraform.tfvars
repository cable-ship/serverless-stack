region = "eu-west-1"

vpc_cidr = "10.20.0.0/16"
azs      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnets = [
  "10.20.1.0/24",
  "10.20.2.0/24",
  "10.20.3.0/24",
]

# Required app inputs
cognito_user_email  = "kmajidwork@gmail.com"           # Cognito user and event payload email
notification_email  = "kmajidwork@gmail.com"   # Receives SNS notifications
repo_url            = "https://github.com/cable-ship/serverless-stack"

external_sns_topic_arn = ""
enable_email_notifications = true  # Set to true to receive email notifications
