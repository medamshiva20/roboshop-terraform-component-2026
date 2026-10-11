locals {
  ami_id = data.aws_ami.sivadevops.id
  private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_ids.value)
  sg_id = data.aws_ssm_parameter.sg_id.value
}