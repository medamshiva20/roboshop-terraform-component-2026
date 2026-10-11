locals {
  ami_id = data.aws_ami.sivadevops.id
  private_subnet_id = split(",",data.aws_ssm_parameter.private_subnet_ids.value)[0]
  sg_id = data.aws_ssm_parameter.sg_id.value

  common_tags = {
    project = var.project
    Terraform = true
    environment = var.environment
  }
}