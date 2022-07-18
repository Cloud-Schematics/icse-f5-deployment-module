##############################################################################
# Create Flow Logs Collector if edge VPC is created
##############################################################################

resource "ibm_is_flow_log" "edge_flow_logs" {
  count          = var.create_flow_logs_collector == true ? 1 : 0
  name           = "${var.prefix}-edge-flow-logs"
  target         = module.edge_vpc.vpc_id
  active         = true
  storage_bucket = var.flow_logs_bucket_name
  resource_group = var.resource_group_id
}

##############################################################################
