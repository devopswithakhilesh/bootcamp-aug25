# # take the code -> zip it -> upload to s3 -> point lambda to s3 bucket

# # zip the code -> data source archive_file
# #b ${path.module} -> root of terraform code

# # looping -> for_each -> it takes eirther a map, or a set but not list
data "archive_file" "lambda_zip" {
    for_each = local.lambda_info_map # each.key and each.value can be used inside this block
  type        = "zip"
  source_dir  = "${path.module}/${each.value.path}" # each.value.path
  output_path = "${path.module}/../functions/${each.key}_payload.zip"
}

# # either you have your own s3 bucket or aws use its own
resource "aws_lambda_function" "lambda" {
    for_each = local.lambda_info_map
  filename         = data.archive_file.lambda_zip[each.key].output_path
  function_name    = "${var.environment}-${each.key}"
  role             = aws_iam_role.lambda[each.key].arn
  handler          = each.value.handler
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  runtime = each.value.runtime

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = var.environment
    Team        = "data-team"
  }
}

resource "aws_iam_role" "lambda" {
    for_each = local.lambda_info_map
    name = "${each.key}-role"

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
        Environment = var.environment
        team = "data-team"
    }
}

resource "aws_iam_policy" "ec2_ses_policy" {
    name        = "single-lambda-policy"
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
                "arn:aws:logs:ap-south-1:879381241087:log-group:/aws/lambda/*"
            ]
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_ses" {
        for_each = local.lambda_info_map
    role       = aws_iam_role.lambda[each.key].name
    policy_arn = aws_iam_policy.ec2_ses_policy.arn
}


# # lambda trigger using cron job - eventbridge
# resource "aws_cloudwatch_event_rule" "daily_lambda_trigger" {
#     name                = "daily-lambda-trigger"
#     description         = "Triggers the daily cloud report lambda every day at 8 AM"
#     schedule_expression = "cron(0 7 * * ? *)" # every day at 8 AM UTC
# }
# resource "aws_cloudwatch_event_target" "lambda_target" {
#     rule      = aws_cloudwatch_event_rule.daily_lambda_trigger.name
#     target_id = "daily-cloud-report-lambda"
#     arn       = aws_lambda_function.lambda.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.daily_lambda_trigger.arn
# }


