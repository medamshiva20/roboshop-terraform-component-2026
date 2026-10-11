locals {
  ami_id = data.aws_ami.sivadevops.id
  private_subnet_id = split(",",data.aws_ssm_parameter.private_subnet_ids.value)[0]
  sg_id = data.aws_ssm_parameter.sg_id.value
  port_number = var.component == "frontend" ? 80 : 8080
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  health_check_path = var.component == "frontend" ? "/" : "/health"

  common_tags = {
    project = var.project
    Terraform = true
    environment = var.environment
  }
}