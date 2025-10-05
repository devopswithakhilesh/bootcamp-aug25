# cretae ecr repository
resource "aws_ecr_repository" "ecr" {
  name = "${var.environment}-${var.app}"
}