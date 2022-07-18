##############################################################################
# F5 Security Group Config
##############################################################################

locals {
  ##############################################################################
  # Security group rules for each security group
  ##############################################################################

  default_security_group_rules = [
    {
      name      = "allow-ibm-inbound"
      remote    = "161.26.0.0/16"
      direction = "inbound"
      tcp = {
        port_min = null
        port_max = null
      }
    },
    {
      name      = "allow-vpc-inbound"
      remote    = "10.0.0.0/8"
      direction = "inbound"
      tcp = {
        port_min = null
        port_max = null
      }
    },
    {
      name      = "allow-vpc-outbound"
      remote    = "10.0.0.0/8"
      direction = "outbound"
      tcp = {
        port_min = null
        port_max = null
      }
    }
  ]

  ibm_service_port_rules = [
    for port in [53, 80, 443] :
    {
      name      = "allow-ibm-tcp-${port}-outbound"
      remote    = "161.26.0.0/16"
      direction = "outbound"
      tcp = {
        port_min = port
        port_max = port
      }
    }
  ]

  all_default_security_group_rules = concat(
    local.default_security_group_rules,
    local.ibm_service_port_rules
  )

  all_bastion_cidr_blocks = concat(
    [
      for zone in [1, 2, 3] :
      "10.${4 + zone}.60.0/24" if zone <= var.bastion_subnet_zones
    ],
    var.bastion_cidr_blocks
  )

  ##############################################################################

  ##############################################################################
  # Security Groups
  ##############################################################################

  security_groups = {

    ##############################################################################
    # F5 Bastion Security Group
    ##############################################################################

    f5-bastion = {
      name = "f5-bastion-sg"
      rules = flatten([
        # For each bastion CIDR create a rule allowing inbound traffic to 3023-3025 and 3080
        for cidr in local.all_bastion_cidr_blocks :
        [
          {
            name      = "allow-bastion-cidr-${index(local.all_bastion_cidr_blocks, cidr) + 1}-inbound-3023-3025"
            direction = "inbound"
            remote    = cidr
            tcp = {
              port_min        = null
              port_max        = null
              source_port_min = 3023
              source_port_max = 3025
            }
          },
          {
            name      = "allow-bastion-cidr-${index(local.all_bastion_cidr_blocks, cidr) + 1}-inbound-3080"
            direction = "inbound"
            remote    = cidr
            tcp = {
              port_min        = null
              port_max        = null
              source_port_max = 3080
              source_port_min = 3080
            }
          },
          {
            name      = "allow-bastion-cidr-${index(local.all_bastion_cidr_blocks, cidr) + 1}-outbound-3023-3025"
            direction = "outbound"
            remote    = cidr
            tcp = {
              port_min        = 3023
              port_max        = 3025
              source_port_max = null
              source_port_min = null
            }
          },
          {
            name      = "allow-bastion-cidr-${index(local.all_bastion_cidr_blocks, cidr) + 1}-outbound-3080"
            direction = "outbound"
            remote    = cidr
            tcp = {
              port_max        = 3080
              port_min        = 3080
              source_port_max = null
              source_port_min = null
            }
          }
        ]
      ])
    }

    ##############################################################################

    ##############################################################################
    # F5 External Security Group
    ##############################################################################

    f5-external = {
      name = "f5-external-sg"
      rules = [
        {
          name      = "allow-inbound-443"
          direction = "inbound"
          remote    = "0.0.0.0/0"
          tcp = {
            port_max        = 443
            port_min        = 443
            source_port_max = null
            source_port_min = null
          }
        },
        {
          name      = "allow-outbound-443"
          direction = "inbound"
          remote    = "0.0.0.0/0"
          tcp = {
            port_min        = null
            port_max        = null
            source_port_max = 443
            source_port_min = 443
          }
        }
      ]
    }

    ##############################################################################

    ##############################################################################
    # F5 Management Security Group    
    ##############################################################################

    f5-management = {
      name = "f5-management-sg"
      rules = flatten([
        [
          # For each bastion CIDR create a rule allowing inbound traffic to 443 and 22
          for cidr in var.bastion_cidr_blocks :
          [
            {
              name      = "allow-bastion-cidr-${index(var.bastion_cidr_blocks, cidr) + 1}-inbound-443"
              direction = "inbound"
              remote    = cidr
              tcp = {
                port_max = 443
                port_min = 443
              }
            },
            {
              name      = "allow-bastion-cidr-${index(var.bastion_cidr_blocks, cidr) + 1}-inbound-22"
              direction = "inbound"
              remote    = cidr
              tcp = {
                port_max = 22
                port_min = 22
              }
            }
          ]
        ],
        local.all_default_security_group_rules
      ])
    }

    ##############################################################################

    ##############################################################################
    # F5 Workload Security Group
    ##############################################################################
    f5-workload = {
      name = "f5-workload-sg"
      rules = concat(
        [
          # for each workload cidr add a rule to allow 443 inbound traffic
          for subnet in var.workload_cidr_blocks :
          {
            name      = "allow-workload-subnet-${index(var.workload_cidr_blocks, subnet) + 1}"
            remote    = subnet
            direction = "inbound"
            tcp = {
              port_max = 443
              port_min = 443
            }
          }
        ],
        local.all_default_security_group_rules
      )
    }
    ##############################################################################
  }
  ##############################################################################
}

##############################################################################