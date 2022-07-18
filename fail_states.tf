##############################################################################
# Fail States
##############################################################################

locals {
  CONFIGURATION_FAILURE_no_bastion_cidr_provided_security_group_incorrect_variable_type = regex(
    "true",
    var.bastion_subnet_zones > 0 ? true : length(local.all_bastion_cidr_blocks) > 0
  )

  CONFIGURATION_FAILURE_conflicting_floating_ips = regex(
    false,
    var.enable_f5_external_fip == true && var.enable_f5_management_fip == true
  )
}

##############################################################################