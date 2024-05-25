locals {
  prefix   = "${var.bu}-${var.project}"
  suffix   = var.env
  region   = var.region
  efs_name = "${local.prefix}-efs-${local.suffix}"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = {
    Businessunit = var.bu
    Environment  = var.env
    TeamName     = "RnD"
    Managedby    = "Terraform"
  }

  jenkins_namespace         = "jenkins"
  jenkins_ebs_storage_class = "ebs-sc"
  jenkins_ebs_pvc           = "ebs-pvc"
}

