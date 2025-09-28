# ECS cluster


# Task defnition


# ECS service




# ECS security group (inbound port 8000 from ALB SG only)

resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Allow inbound traffic on port 8000 from ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow inbound from ALB SG"
    from_port       = 8000
    to_port         = 8000
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
    Name = "ecs-service-sg"
  }
}