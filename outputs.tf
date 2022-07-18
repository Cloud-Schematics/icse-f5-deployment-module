##############################################################################
# Edge Network Outputs
##############################################################################

output "vpc_id" {
  description = "ID of edge VPC"
  value       = module.edge_vpc.vpc_id
}

output "network_acl" {
  description = "Network ACL name and ID"
  value       = module.edge_vpc.network_acl
}

output "public_gateways" {
  description = "Edge VPC public gateways"
  value       = module.edge_vpc.public_gateways
}

output "subnet_zone_list" {
  description = "List of subnet ids, cidrs, names, and zones."
  value       = module.edge_vpc.subnet_zone_list
}

output "subnet_tiers" {
  description = "Map of subnet tiers where each key contains the subnet zone list for that tier."
  value = module.edge_vpc.subnet_tiers
}

##############################################################################

##############################################################################
# F5 Security Group Outputs
##############################################################################

output security_groups {
  description = "List of security groups created."
  value       = module.f5_security_groups.groups
}

##############################################################################

##############################################################################
# Virtual Server Outputs
##############################################################################

output virtual_servers {
  description = "List of virtual servers created by this module."
  value       = [
    for instance in keys(module.f5_vsi_map.value):
    module.vsi_deployment[instance].virtual_servers
  ]
}

##############################################################################