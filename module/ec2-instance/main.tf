resource "aws_instance" "this" {
  count                  = var.ec2_instance_config.instance_count
  ami                    = var.ec2_instance_config.ami
  instance_type          = var.ec2_instance_config.instance_type
  key_name               = var.ec2_instance_config.key_name
  subnet_id              = var.ec2_instance_config.subnet_id
  vpc_security_group_ids = var.ec2_instance_config.vpc_security_group_ids

  iam_instance_profile = var.ec2_instance_config.iam_instance_profile

  root_block_device {
    volume_size = var.ec2_instance_config.root_block_device.volume_size
    volume_type = var.ec2_instance_config.root_block_device.volume_type
  }

  user_data = var.ec2_instance_config.user_data

  tags = var.ec2_instance_config.tags
}
