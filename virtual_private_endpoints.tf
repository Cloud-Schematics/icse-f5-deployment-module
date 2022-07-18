##############################################################################
# Create VPE security group if enabled
##############################################################################

module "vpe_security_group" {
  source = "github.com/Cloud-Schematics/vpc-security-group-module"
  count  = var.create_vpe_subnet_tier == true ? 1 : 0
  prefix = var.prefix
  tags   = var.tags
  vpc_id = module.edge_vpc.vpc_id
  security_groups = [
    {
      name = "edge-vpe-sg"
      rules = flatten([
        # Create global allow inbound and outbound rules
        [
          for cidr in var.global_inbound_allow_list :
          {
            name      = "allow-all-edge-vpe-inbound-${index(var.global_inbound_allow_list, cidr) + 1}"
            direction = "inbound"
            remote    = cidr
          }
        ],
        [
          for cidr in var.global_outbound_allow_list :
          {
            name      = "allow-all-edge-vpe-outbound-${index(var.global_outbound_allow_list, cidr) + 1}"
            direction = "outbound"
            remote    = cidr
          }
        ]
      ])
    }
  ]
}

##############################################################################

##############################################################################
# VPE Subnet List
##############################################################################

module "vpe_subnets" {
  source           = "github.com/Cloud-Schematics/get-subnets"
  count            = var.create_vpe_subnet_tier == true ? 1 : 0
  subnet_zone_list = module.edge_vpc.subnet_zone_list
  regex            = "-vpe-"
}

##############################################################################

##############################################################################
# Create VPE if enabled
##############################################################################

module "virtual_private_endpoints" {
  source             = "github.com/Cloud-Schematics/vpe-module"
  count              = var.create_vpe_subnet_tier == true ? 1 : 0
  prefix             = var.prefix
  region             = var.region
  vpc_name           = "edge"
  vpc_id             = module.edge_vpc.vpc_id
  subnet_zone_list   = module.vpe_subnets[0].subnets
  resource_group_id  = var.resource_group_id
  cloud_services     = var.vpe_services
  service_endpoints  = "private"
  security_group_ids = module.vpe_security_group[0].groups.*.id
}

##############################################################################