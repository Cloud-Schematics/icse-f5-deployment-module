##############################################################################
# Template Data
# > template config from 
#   https://github.com/f5devcentral/ibmcloud_schematics_bigip_multinic_public_images
##############################################################################

locals {
  template_config = {
    ##############################################################################
    # Prevent string template configuration errors by forcing null string literal
    ##############################################################################
    byol_license_basekey    = lookup(var.f5_template_data, "byol_license_basekey", null) == null ? "null" : lookup(var.f5_template_data, "byol_license_basekey")
    license_host            = lookup(var.f5_template_data, "license_host", null) == null ? "null" : lookup(var.f5_template_data, "license_host")
    license_username        = lookup(var.f5_template_data, "license_username", null) == null ? "null" : lookup(var.f5_template_data, "license_username")
    license_password        = lookup(var.f5_template_data, "license_password", null) == null ? "null" : lookup(var.f5_template_data, "license_password")
    license_pool            = lookup(var.f5_template_data, "license_pool", null) == null ? "null" : lookup(var.f5_template_data, "license_pool")
    license_sku_keyword_1   = lookup(var.f5_template_data, "license_sku_keyword_1", null) == null ? "null" : lookup(var.f5_template_data, "license_sku_keyword_1")
    license_sku_keyword_2   = lookup(var.f5_template_data, "license_sku_keyword_2", null) == null ? "null" : lookup(var.f5_template_data, "license_sku_keyword_2")
    license_unit_of_measure = lookup(var.f5_template_data, "license_unit_of_measure ", null) == null ? "null" : lookup(var.f5_template_data, "license_unit_of_measure")
    ##############################################################################
  }
  ##############################################################################
  # License YAML
  ##############################################################################
  do_byol_license = <<EOD
    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      byoLicense:
        class: License
        licenseType: regKey
        regKey: ${local.template_config.byol_license_basekey}
EOD
  do_regekypool   = <<EOD
    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      poolLicense:
        class: License
        licenseType: licensePool
        bigIqHost: ${local.template_config.license_host}
        bigIqUsername: ${local.template_config.license_username}
        bigIqPassword: ${local.template_config.license_password}
        licensePool: ${local.template_config.license_pool}
        reachable: false
        hypervisor: kvm
EOD
  do_utilitypool  = <<EOD
    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      utilityLicense:
        class: License
        licenseType: licensePool
        bigIqHost: ${local.template_config.license_host}
        bigIqUsername: ${local.template_config.license_username}
        bigIqPassword: ${local.template_config.license_password}
        licensePool: ${local.template_config.license_pool}
        skuKeyword1: ${local.template_config.license_sku_keyword_1}
        skuKeyword2: ${local.template_config.license_sku_keyword_2}
        unitOfMeasure: ${local.template_config.license_unit_of_measure}
        reachable: false
        hypervisor: kvm
EOD
  ##############################################################################
  template_file        = file("${path.module}/user_data.yaml")
  do_dec1              = var.f5_template_data.license_type == "byol" ? chomp(local.do_byol_license) : "null"
  do_dec2              = var.f5_template_data.license_type == "regkeypool" ? chomp(local.do_regekypool) : local.do_dec1
  do_local_declaration = var.f5_template_data.license_type == "utilitypool" ? chomp(local.do_utilitypool) : local.do_dec2
}

##############################################################################

##############################################################################
# Create template user data for each VSI
##############################################################################

data "template_file" "f5_user_data" {
  for_each = {
    # create a key where the zone points to the the vsi instance in local
    # vsi list (main.tfL#62)
    for zone in [1, 2, 3] :
    "${var.region}-${zone}" => local.f5_vsi_list[zone - 1] if zone <= var.zones
  }
  template = local.template_file
  vars = {
    configsync_interface    = "1.1"
    zone                    = each.key
    vpc                     = module.edge_vpc.vpc_id
    tmos_admin_password     = var.f5_template_data.tmos_admin_password
    hostname                = var.f5_template_data.hostname
    domain                  = var.f5_template_data.domain
    do_local_declaration    = local.do_local_declaration
    default_route_interface = var.f5_template_data.default_route_interface == null ? "1.${length(each.value.secondary_subnets)}" : var.f5_template_data.default_route_interface
    default_route_gateway   = cidrhost(each.value.secondary_subnets[length(each.value.secondary_subnets) - 1].cidr, 1)
    ##############################################################################
    # Prevent string template configuration errors by forcing null string literal
    ##############################################################################
    do_declaration_url  = lookup(var.f5_template_data, "do_declaration_url", null) == null ? "null" : lookup(var.f5_template_data, "do_declaration_url", null)
    as3_declaration_url = lookup(var.f5_template_data, "as3_declaration_url", null) == null ? "null" : lookup(var.f5_template_data, "as3_declaration_url", null)
    ts_declaration_url  = lookup(var.f5_template_data, "ts_declaration_url", null) == null ? "null" : lookup(var.f5_template_data, "ts_declaration_url", null)
    phone_home_url      = lookup(var.f5_template_data, "phone_home_url", null) == null ? "null" : lookup(var.f5_template_data, "phone_home_url", null)
    template_source     = lookup(var.f5_template_data, "template_source", null) == null ? "null" : lookup(var.f5_template_data, "template_source", null)
    template_version    = lookup(var.f5_template_data, "template_version", null) == null ? "null" : lookup(var.f5_template_data, "template_version", null)
    app_id              = lookup(var.f5_template_data, "app_id", null) == null ? "null" : lookup(var.f5_template_data, "app_id", null)
    tgactive_url        = lookup(var.f5_template_data, "tgactive_url", null) == null ? "null" : lookup(var.f5_template_data, "tgactive_url", null)
    tgstandby_url       = lookup(var.f5_template_data, "tgstandby_url", null) == null ? "null" : lookup(var.f5_template_data, "tgstandby_url", null)
    tgrefresh_url       = lookup(var.f5_template_data, "tgrefresh_url", null) == null ? "null" : lookup(var.f5_template_data, "tgrefresh_url", null)
    ##############################################################################
  }
}


##############################################################################