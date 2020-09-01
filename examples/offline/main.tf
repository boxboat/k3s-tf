provider "aws" {
  version = "~> 3.0"
}

module "k3s" {
  source = "../../"

  name = var.name

  vpc_id  = var.vpc_id
  subnets = var.subnets

  tags = var.tags
}

# Primary server nodepool
module "servers" {
  source = "../../modules/nodepool"

  # Node variables
  vpc_id               = var.vpc_id
  subnets              = var.subnets
  cluster              = module.k3s.cluster
  ami                  = var.ami
  iam_instance_profile = var.iam_instance_profile

  # Cluster variables
  name                      = "primary-servers"
  cluster_security_group    = module.k3s.cluster_security_group
  extra_security_groups     = [module.k3s.shared_server_security_group]
  controlplane_loadbalancer = module.k3s.controlplane_loadbalancer
  state_bucket              = var.state_bucket

  rancher_rpm_repo_baseurl = "s3://rancher-migration-bucket/rancher-airgap"

  # K3S Variables
  k3s_tls_sans    = [module.k3s.tls_san]
  k3s_node_labels = ["type=primary-server"]

  tags = var.tags
}

# Generic agent nodepool
//module "generic_agents" {
//  source     = "../../modules/nodepool"
//  depends_on = [module.k3s]
//
//  vpc_id  = var.vpc_id
//  subnets = var.subnets
//
//  name                 = "generic-agents"
//  cluster              = module.k3s.cluster
//  ami                  = var.ami
//  iam_instance_profile = var.iam_instance_profile
//  spot                 = true
//  pre_userdata         = local.pre_userdata
//  min                  = 1
//  max                  = 3
//  desired              = 2
//
//  k3s_token = module.k3s.token
//  k3s_url   = module.k3s.url
//
//  tags = var.tags
//}

# NOTE: Nothing with the bootstrap process requires ssh, but for this example we open ssh on the server nodes for example purposes
resource "aws_security_group_rule" "ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.k3s.cluster_security_group
  type              = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
}