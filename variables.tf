##############################################################################
# Module Variables
##############################################################################

variable "prefix" {
  description = "The prefix that you would like to prepend to your resources"
  type        = string
}

variable "tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

variable "resource_group_id" {
  description = "Resource group ID for the VSI"
  type        = string
  default     = null
}

variable "region" {
  description = "The region where components will be created"
  type        = string
}

##############################################################################

##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  description = "ID of the VPC where VSI will be provisioned. If VPC ID is `null`, a VPC will be created automatically."
  type        = string
  default     = null
}

variable "existing_public_gateways" {
  description = "Use existing public gateways for VPC id if not creating. If creating a new VPC this value will be ignored."
  type = object({
    zone-1 = string
    zone-2 = string
    zone-3 = string
  })
  default = {
    zone-1 = null
    zone-2 = null
    zone-3 = null
  }
}

variable "create_public_gateways" {
  description = "Create public gateways on the VPC. Public gateways will be created in each zone where an existing public gateway id has not been passed in using the `existing_public_gateways` variable. Public gateways will not be created in zones greater than the `zones` variable. Set to true when using WAF."
  type        = bool
  default     = true
}

variable "create_vpc_options" {
  description = "Options to use when using this module to create a VPC."
  type = object({
    classic_access              = optional(bool)
    default_network_acl_name    = optional(string)
    default_security_group_name = optional(string)
    default_routing_table_name  = optional(string)
  })
  default = {
    classic_access              = false
    default_network_acl_name    = null
    default_security_group_name = null
    default_routing_table_name  = null
  }
}

variable "zones" {
  description = "Number of zones for edge VPC creation"
  type        = number
  default     = 3

  validation {
    error_message = "VPCs zones can only be 1, 2, or 3."
    condition     = var.zones > 0 && var.zones < 4
  }
}

##############################################################################

##############################################################################
# Network ACL Variables
##############################################################################

variable "add_cluster_rules" {
  description = "Automatically add needed ACL rules to allow each network to create and manage Openshift and IKS clusters."
  type        = bool
  default     = false
}

variable "global_inbound_allow_list" {
  description = "List of CIDR blocks where inbound traffic will be allowed. These allow rules will be added to each network acl."
  type        = list(string)
  default = [
    "10.0.0.0/8",   # Internal network traffic
    "161.26.0.0/16" # IBM Network traffic
  ]

  validation {
    error_message = "Global inbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_inbound_allow_list) == 0 ? true : (
      length(var.global_inbound_allow_list) == length(distinct(var.global_inbound_allow_list))
    )
  }
}

variable "global_outbound_allow_list" {
  description = "List of CIDR blocks where outbound traffic will be allowed. These allow rules will be added to each network acl."
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]

  validation {
    error_message = "Global outbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_outbound_allow_list) == 0 ? true : (
      length(var.global_outbound_allow_list) == length(distinct(var.global_outbound_allow_list))
    )
  }
}

variable "global_inbound_deny_list" {
  description = "List of CIDR blocks where inbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules."
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]

  validation {
    error_message = "Global inbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_inbound_deny_list) == 0 ? true : (
      length(var.global_inbound_deny_list) == length(distinct(var.global_inbound_deny_list))
    )
  }
}

variable "global_outbound_deny_list" {
  description = "List of CIDR blocks where outbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules."
  type        = list(string)
  default     = []

  validation {
    error_message = "Global outbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_outbound_deny_list) == 0 ? true : (
      length(var.global_outbound_deny_list) == length(distinct(var.global_outbound_deny_list))
    )
  }
}

##############################################################################

##############################################################################
# Subnet Variables
##############################################################################

variable "create_vpn_1_subnet_tier" {
  description = "Create VPN-1 subnet tier."
  type        = bool
  default     = true
}

variable "create_vpn_2_subnet_tier" {
  description = "Create VPN-1 subnet tier."
  type        = bool
  default     = true
}

variable "bastion_subnet_zones" {
  description = "Create Bastion subnet tier for each zone in this list. Bastion subnets created cannot exceed number of zones in `var.zones`. These subnets are reserved for future bastion VSI deployment."
  type        = number
  default     = 1

  validation {
    error_message = "Bastion subnet zones can be 0, 1, 2, or 3."
    condition     = var.bastion_subnet_zones >= 0 && var.bastion_subnet_zones < 4
  }
}

##############################################################################

##############################################################################
# VPE Services
##############################################################################

variable "create_vpe_subnet_tier" {
  description = "Create VPE subnet tier on edge VPC. Leave as false if provisioning network that already contains VPEs."
  type        = bool
  default     = false
}

variable "vpe_services" {
  description = "List of VPE Services to use to create endpoint gateways."
  type        = list(string)
  default     = ["cloud-object-storage", "kms"]
}

##############################################################################

##############################################################################
# F5 Network Variables
##############################################################################

variable "vpn_firewall_type" {
  description = "F5 type. Can be `full-tunnel`, `waf`, or `vpn-and-waf`."
  type        = string

  validation {
    error_message = "Bastion type must be `full-tunnel`, `waf`, `vpn-and-waf` or `null`."
    condition     = contains(["full-tunnel", "waf", "vpn-and-waf"], var.vpn_firewall_type)
  }
}

variable "workload_cidr_blocks" {
  description = "List of workload CIDR blocks. This is used to create security group rules for the F5 management interface."
  type        = list(string)
  default     = []
}

variable "bastion_cidr_blocks" {
  description = "List of bastion VSI CIDR blocks. These CIDR blocks are used to allow connections from the bastion CIDR to the F5 management interface. CIDR blocks from dynamically generated `bastion` tier are added automatically."
  type        = list(string)
  default     = []
}

##############################################################################

##############################################################################
# F5 Instance Data Variables
##############################################################################

variable "f5_template_data" {
  description = "Data for all f5 templates"
  sensitive   = true
  type = object({
    domain                  = string
    hostname                = string
    license_type            = string
    tmos_admin_password     = string
    byol_license_basekey    = optional(string)
    default_route_interface = optional(string)
    license_host            = optional(string)
    license_username        = optional(string)
    license_password        = optional(string)
    license_pool            = optional(string)
    license_sku_keyword_1   = optional(string)
    license_sku_keyword_2   = optional(string)
    license_unit_of_measure = optional(string)
    do_declaration_url      = optional(string)
    as3_declaration_url     = optional(string)
    ts_declaration_url      = optional(string)
    phone_home_url          = optional(string)
    template_source         = optional(string)
    template_version        = optional(string)
    app_id                  = optional(string)
    tgactive_url            = optional(string)
    tgstandby_url           = optional(string)
    tgrefresh_url           = optional(string)
  })

  default = {
    domain              = "test.com"
    hostname            = "example"
    tmos_admin_password = "Iamapassword2ru"
    license_type        = "none"
  }

  validation {
    error_message = "Value for tmos_password must be at least 15 characters, contain one numeric, one uppercase, and one lowercase character."
    condition = lookup(var.f5_template_data, "tmos_admin_password") == null ? true : (
      length(var.f5_template_data.tmos_admin_password) >= 15
      && can(regex("[A-Z]", var.f5_template_data.tmos_admin_password))
      && can(regex("[a-z]", var.f5_template_data.tmos_admin_password))
      && can(regex("[0-9]", var.f5_template_data.tmos_admin_password))
    )
  }

  validation {
    error_message = "License type may be one of 'none','byol','regkeypool','utilitypool'."
    condition     = contains(["none", "byol", "regkeypool", "utilitypool"], var.f5_template_data.license_type)
  }
}

##############################################################################

##############################################################################
# Virtual Server Variables
##############################################################################

variable "create_encryption_key" {
  description = "Create encryption key for module."
  type        = bool
  default     = true
}

variable "kms_guid" {
  description = "GUID of the key management service where an encryption key for virtual servers will be stored."
  type        = string
  default     = null
}

variable "key_management_endpoint_type" {
  description = "Endpoint type for encryption key provision. Can be `public` or `private`. Use `public` for provision via local machine."
  type        = string
  default     = "public"

  validation {
    error_message = "Key management endpoint type must be `public` or `private`."
    condition     = contains(["public", "private"], var.key_management_endpoint_type)
  }
}

variable "deployment_name" {
  description = "Name of the virtual server deployment. The prefix will be prepended to this name and the zone added to the end. ex. `<your prefix>-<deployment name>-<zone>."
  type        = string
  default     = "f5"
}

variable "f5_image_name" {
  description = "Name of the F5 Big IP image to use for module. Image ID will be dynamically looked up using the map in `f5_config_image.tf` based on region.  Must be one of `f5-bigip-15-1-5-1-0-0-14-all-1slot`,`f5-bigip-15-1-5-1-0-0-14-ltm-1slot`, `f5-bigip-16-1-2-2-0-0-28-ltm-1slot`,`f5-bigip-16-1-2-2-0-0-28-all-1slot`]."
  type        = string
  default     = "f5-bigip-16-1-2-2-0-0-28-all-1slot"

  validation {
    error_message = "Invalid F5 image name. Must be one of `f5-bigip-15-1-5-1-0-0-14-all-1slot`,`f5-bigip-15-1-5-1-0-0-14-ltm-1slot`, `f5-bigip-16-1-2-2-0-0-28-ltm-1slot`,`f5-bigip-16-1-2-2-0-0-28-all-1slot`]."
    condition     = contains(["f5-bigip-15-1-5-1-0-0-14-all-1slot", "f5-bigip-15-1-5-1-0-0-14-ltm-1slot", "f5-bigip-16-1-2-2-0-0-28-ltm-1slot", "f5-bigip-16-1-2-2-0-0-28-all-1slot"], var.f5_image_name)
  }
}

variable "profile" {
  description = "Type of machine profile for VSI. Use the command `ibmcloud is instance-profiles` to find available profiles in your region"
  type        = string
  default     = "cx2-4x8"
}

variable "ssh_key_ids" {
  description = "List of SSH Key IDs to use when provisioning virtual server instances."
  type        = list(string)

  validation {
    error_message = "At least one SSH Key must be provided."
    condition     = length(var.ssh_key_ids) > 0
  }
}

variable "enable_f5_management_fip" {
  description = "Enable F5 management interface floating IP. Conflicts with `enable_f5_external_fip`, VSI can only have one floating IP per instance."
  type        = bool
  default     = false
}

variable "enable_f5_external_fip" {
  description = "Enable F5 external interface floating IP. Conflicts with `enable_f5_management_fip`, VSI can only have one floating IP per instance."
  type        = bool
  default     = true
}

##############################################################################

##############################################################################
# Flow Logs Variables
##############################################################################

variable "create_flow_logs_collector" {
  description = "Create flow logs collector for VPC. Collectors will only be created if `vpc_id` is `null` and a COS bucket name is provided."
  type        = bool
  default     = true
}

variable "flow_logs_bucket_name" {
  description = "Flow logs collector bucket name"
  type        = string
  default     = null
}

##############################################################################