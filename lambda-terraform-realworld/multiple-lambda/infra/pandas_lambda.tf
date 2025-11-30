data "archive_file" "lambda_zip_1" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/panda_usecase"
  output_path = "${path.module}/../functions/panda_usecase_payload.zip"
}

# https://aws-sdk-pandas.readthedocs.io/en/stable/layers.html
# arn:aws:lambda:ap-south-1:336392948345:layer:AWSSDKPandas-Python312:20
resource "aws_lambda_function" "lambda_1" {
  filename         = data.archive_file.lambda_zip_1.output_path
  function_name    = "pandas-usecase"
  role             = aws_iam_role.pandas.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.lambda_zip_1.output_base64sha256

  runtime = "python3.12"
  # layers = "arn:aws:lambda:ap-south-1:336392948345:layer:AWSSDKPandas-Python312:20"

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
resource "aws_iam_role" "pandas" {
    name = "pandas-usecase-lambda-role"

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


resource "aws_iam_role_policy_attachment" "pandas_basic_execution" {
    role       = aws_iam_role.pandas.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}