data "aws_ami" "ami" {
  most_recent      = true
  owners           = ["973714476881"]

  filter {
    name   = "name"
    values = ["Redhat-9-DevOps-Practice"]
  }
}

data "aws_ssm_parameter" "private-snet" {
  name = "/${var.project}/${var.environment}/private-snet" 
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/${var.environment}/vpc_id" 
}

data "aws_ssm_parameter" "sg_id" {
  name = "/${var.project}/${var.environment}/${var.component}-sg-id" 
}

data "aws_ssm_parameter" "listener_arn" {
  name = "/${var.project}/${var.environment}/listener_arn" 
}

