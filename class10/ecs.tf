# 879381241087.dkr.ecr.ap-south-1.amazonaws.com/ecs-studentportal:1.0

# ECS cluster
resource "aws_ecs_cluster" "ecs" {
  name = "${var.environment}-${var.app}-cluster"

}

# Task defnition
resource "aws_ecs_task_definition" "ecs" {
  #checkov:skip=CKV_AWS_336: The ECS task needs write access to system
  family = "${var.environment}-${var.app}-task-def"
  container_definitions = jsonencode(
    [
      {
        "name" : "${var.ecs_app_values["container_name"]}",
        "image" : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecs-studentportal:1.0",
        "portMappings" = [
          {
            "containerPort" = tonumber("${var.ecs_app_values["container_port"]}"),
            "hostPort"      = tonumber("${var.ecs_app_values["container_port"]}")
          }
        ],
        "essential" : true,
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : aws_cloudwatch_log_group.ecs.name,
            "awslogs-region" : data.aws_region.current.name,
            "awslogs-stream-prefix" : "ecs"
          },
        },
        "environment" : [
          {
            "name" : "DB_LINK",
            "value" : "postgresql://${aws_db_instance.postgres.username}:${random_password.dbs_random_string.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
          },

        ]
      }
  ])

  cpu = 256
  # role for task to pull the ecr image
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  memory             = var.ecs_app_values["memory"]
  network_mode       = "awsvpc"
  requires_compatibilities = [
    var.ecs_app_values["launch_type"],
  ]

}

# ECS service

resource "aws_ecs_service" "ecs" {
  name                       = "${var.environment}-${var.app}-service"
  cluster                    = aws_ecs_cluster.ecs.id
  task_definition            = aws_ecs_task_definition.ecs.arn
  desired_count              = 2
  deployment_maximum_percent = 250 # 
  launch_type                = var.ecs_app_values["launch_type"]

  deployment_configuration{
    strategy = BLUE_GREEN
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_service_sg.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb.arn
    container_name   = var.ecs_app_values["container_name"]
    container_port   = var.ecs_app_values["container_port"]
  }

  depends_on = [
    aws_iam_role.ecs_task_execution_role,
  ]

}


# ECS security group (inbound port 8000 from ALB SG only)

resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.environment}-${var.app}-ecs-sg"
  description = "Allow inbound traffic on port 8000 from ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow inbound from ALB SG"
    from_port       = var.ecs_app_values["container_port"]
    to_port         = var.ecs_app_values["container_port"]
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.app}-ecs-sg"
  }
}


# auto-scaling for ecs service

# target

# scaling policy

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.ecs.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_scaling_policy" {
  name               = "${var.environment}-${var.app}-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 30
    scale_out_cooldown = 30
  }
}

