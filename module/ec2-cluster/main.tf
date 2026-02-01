locals {
  enabled = var.ec2_cluster_config.enabled
}

resource "aws_instance" "master" {
  count                  = local.enabled ? var.ec2_cluster_config.master_count : 0
  ami                    = var.ec2_cluster_config.ami
  instance_type          = var.ec2_cluster_config.master_instance_type
  key_name               = var.ec2_cluster_config.key_name
  subnet_id              = var.ec2_cluster_config.subnet_id
  vpc_security_group_ids = var.ec2_cluster_config.vpc_security_group_ids
  iam_instance_profile   = var.ec2_cluster_config.iam_instance_profile
  user_data              = var.ec2_cluster_config.master_user_data
  tags                   = merge(var.ec2_cluster_config.tags, { Role = "Master" })
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

resource "aws_instance" "worker" {
  count                  = local.enabled ? var.ec2_cluster_config.worker_count : 0
  ami                    = var.ec2_cluster_config.ami
  instance_type          = var.ec2_cluster_config.worker_instance_type
  key_name               = var.ec2_cluster_config.key_name
  subnet_id              = var.ec2_cluster_config.subnet_id
  vpc_security_group_ids = var.ec2_cluster_config.vpc_security_group_ids
  iam_instance_profile   = var.ec2_cluster_config.iam_instance_profile
  user_data              = var.ec2_cluster_config.worker_user_data
  tags                   = merge(var.ec2_cluster_config.tags, { Role = "Worker" })
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}
