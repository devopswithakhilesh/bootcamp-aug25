resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/${var.environment}/aws/ecs/august-ecs"
  retention_in_days = 30
}


resource "aws_cloudwatch_query_definition" "ecs" {
  name = "${var.environment}-ecs-query"

  log_group_names = [
    aws_cloudwatch_log_group.ecs.name,
  ]

  query_string = <<-EOF
    filter @message not like /.+Waiting.+/
    | fields @timestamp, @message
    | sort @timestamp desc
    | limit 200
  EOF
}