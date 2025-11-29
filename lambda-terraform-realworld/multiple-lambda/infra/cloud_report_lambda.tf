# take the code -> zip it -> upload to s3 -> point lambda to s3 bucket

# zip the code -> data source archive_file
#b ${path.module} -> root of terraform code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/cloud_report"
  output_path = "${path.module}/../functions/cloud_report_payload.zip"
}

# either you have your own s3 bucket or aws use its own
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "daily-cloud-report"
  role             = aws_iam_role.example.arn
  handler          = "main.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}

resource "aws_iam_role" "example" {
    name = "daily-cloud-report-lambda-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Environment = "production"
        Application = "example"
    }
}

resource "aws_iam_policy" "ec2_ses_policy" {
    name        = "daily-cloud-report-ec2-ses-policy"
    description = "Allows read-only EC2 actions and SES send email permissions for the lambda"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ec2:*",
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "ses:SendEmail",
                    "ses:SendRawEmail"
                ]
                Resource = "*"
            },
            {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:ap-south-1:879381241087:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:ap-south-1:879381241087:log-group:/aws/lambda/daily-cloud-report:*"
            ]
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_ses" {
    role       = aws_iam_role.example.name
    policy_arn = aws_iam_policy.ec2_ses_policy.arn
}


# lambda trigger using cron job - eventbridge
resource "aws_cloudwatch_event_rule" "daily_lambda_trigger" {
    name                = "daily-lambda-trigger"
    description         = "Triggers the daily cloud report lambda every day at 8 AM"
    schedule_expression = "cron(0 7 * * ? *)" # every day at 8 AM UTC
}
resource "aws_cloudwatch_event_target" "lambda_target" {
    rule      = aws_cloudwatch_event_rule.daily_lambda_trigger.name
    target_id = "daily-cloud-report-lambda"
    arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_lambda_trigger.arn
}


