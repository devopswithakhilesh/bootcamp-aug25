variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  #   default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "augustbootcamp-studentportal"
}

variable "app" {
  description = "The name of the application"
  type        = string
  default     = "studentportal"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "A list of CIDR blocks for the subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

}


# list = [1,2,3,4,5] -- index -> 0,1,2,3,4 
# list[0] = 1
# list[1] = 2


variable "rds_defults" {
  type        = map(string)
  description = "values for rds instance"

  default = {
    allocated_storage     = "30"
    max_allocated_storage = "50"
    engine                = "postgres"
    engine_version        = "14.15"
    instance_class        = "db.t3.micro"
    username              = "postgres"
  }
}

variable "ecs_app_values" {
  type        = map(string)
  description = "values for ecs application"

  default = {
    container_name = "studentportal"
    container_port = "8000"
    cpu            = "256"
    memory         = "512"
    desired_count  = "1"
    launch_type    = "FARGATE"
    domain_name    = "akhileshmishra.tech"
    subdomain_name = "studentportal"
  }

}

