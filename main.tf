##############################################################################
# Edge VPC
##############################################################################

module "edge_vpc" {
  source                     = "github.com/Cloud-Schematics/icse-edge-vpc-network"
  prefix                     = var.prefix
  tags                       = var.tags
  resource_group_id          = var.resource_group_id
  region                     = var.region
  vpc_id                     = var.vpc_id
  create_vpc_options         = var.create_vpc_options
  zones                      = var.zones
  existing_public_gateways   = var.existing_public_gateways
  create_public_gateways     = var.create_public_gateways
  add_cluster_rules          = var.add_cluster_rules
  global_inbound_allow_list  = var.global_inbound_allow_list
  global_outbound_allow_list = var.global_outbound_allow_list
  global_inbound_deny_list   = var.global_inbound_deny_list
  global_outbound_deny_list  = var.global_outbound_deny_list
  create_vpe_subnet_tier     = var.create_vpe_subnet_tier
  create_vpn_1_subnet_tier   = var.create_vpn_1_subnet_tier
  create_vpn_2_subnet_tier   = var.create_vpn_2_subnet_tier
  bastion_subnet_zones       = var.bastion_subnet_zones
  vpn_firewall_type          = var.vpn_firewall_type
}

##############################################################################

##############################################################################
# Edge Security Group Locals
##############################################################################

locals {
  vpn_firewall_types = {
    full-tunnel = ["f5-management", "f5-external", "f5-bastion"]
    waf         = ["f5-management", "f5-external", "f5-workload"]
    vpn-and-waf = ["f5-management", "f5-external", "f5-workload", "f5-bastion"]
  }

  module_f5_tier_list = local.vpn_firewall_types[var.vpn_firewall_type]
}

##############################################################################

##############################################################################
# Create Security Groups
##############################################################################

module "f5_security_groups" {
  source = "github.com/Cloud-Schematics/vpc-security-group-module"
  prefix = var.prefix
  tags   = var.tags
  vpc_id = module.edge_vpc.vpc_id
  security_groups = [
    for group in local.module_f5_tier_list :
    local.security_groups[group]
  ]
}

##############################################################################