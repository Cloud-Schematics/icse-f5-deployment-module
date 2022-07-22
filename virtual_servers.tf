##############################################################################
# Create VSI List
##############################################################################

locals {
  f5_vsi_list = [
    for zone in [1, 2, 3] :
    {
      name           = "${var.deployment_name}-zone-${zone}"
      primary_subnet = module.edge_vpc.subnet_tiers["f5-management"][zone - 1]
      secondary_subnets = [
        # for each tier in the current firewall type create secondary subnet
        # object if not in management tier
        for tier in local.module_f5_tier_list :
        merge(
          # merge zone list object with config values
          module.edge_vpc.subnet_tiers[tier][zone - 1],
          {
            shortname         = tier # add shortname
            allow_ip_spoofing = true # add ip spoofing for each secondary ip
            security_group_ids = [   # add security groups
              module.f5_security_groups.groups[index(local.module_f5_tier_list, tier)].id
            ]
          }
        ) if tier != "f5-management"
      ]
    } if zone <= var.zones
  ]
}

##############################################################################

##############################################################################
# F5 server Key Management encryption key
##############################################################################

resource "ibm_kms_key" "f5_vsi_key" {
  count         = var.create_encryption_key != true ? 0 : 1
  instance_id   = var.kms_guid
  key_name      = "${var.prefix}-f5-key"
  standard_key  = false
  endpoint_type = var.key_management_endpoint_type
}

##############################################################################

##############################################################################
# F5 VSI Deployment
##############################################################################

module "f5_vsi_map" {
  source = "github.com/Cloud-Schematics/list-to-map"
  list   = var.provision_f5_vsi == true ? local.f5_vsi_list : {}
}

module "vsi_deployment" {
  source                     = "github.com/Cloud-Schematics/icse-vsi-deployment"
  for_each                   = module.f5_vsi_map.value
  prefix                     = var.prefix
  tags                       = var.tags
  resource_group_id          = var.resource_group_id
  profile                    = var.profile
  ssh_key_ids                = var.ssh_key_ids
  add_floating_ip            = var.enable_f5_management_fip
  vpc_id                     = module.edge_vpc.vpc_id
  deployment_name            = each.key
  image_id                   = true
  vsi_per_subnet             = 1
  image_name                 = local.public_image_map[var.f5_image_name][var.region]
  subnet_zone_list           = [each.value.primary_subnet]
  primary_security_group_ids = [module.f5_security_groups.groups[0].id]
  secondary_subnet_zone_list = each.value.secondary_subnets
  secondary_floating_ips     = var.enable_f5_external_fip == true ? ["f5-external"] : []
  boot_volume_encryption_key = var.create_encryption_key != true ? null : ibm_kms_key.f5_vsi_key[0].crn
  user_data                  = data.template_file.f5_user_data[each.value.primary_subnet.zone].rendered
}

##############################################################################