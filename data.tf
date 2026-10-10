data "aws_ami" "sivadevops" {
  most_recent      = true
  owners           = ["512880382412"]

  filter {
    name   = "name"
    values = ["Siva_AMI"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ssm_parameter" "private_subnet_ids" {
    name = "/${var.project}/${var.environment}/private_subnet_ids"
}

data "aws_ssm_parameter" "sg_id" {
    name = "/${var.project}/${var.environment}/${var.component}_sg_id"
}

data "aws_ssm_parameter" "backend_alb_listener_arn" {
    name = "/${var.project}/${var.environment}/backend_alb_listener_arn"
}

data "aws_ssm_parameter" "frontend_alb_listener_arn" {
    name = "/${var.project}/${var.environment}/frontend_alb_listener_arn"
}

data "aws_ssm_parameter" "vpc_id" {
    name = "/${var.project}/${var.environment}/vpc_id"
}