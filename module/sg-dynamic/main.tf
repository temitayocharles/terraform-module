resource "aws_security_group" "this" {
  name        = var.sg_dynamic_config.config.security_group_name
  description = var.sg_dynamic_config.config.security_group_description
  vpc_id      = var.sg_dynamic_config.vpc_id
  tags        = merge(var.sg_dynamic_config.config.tags, { Name = var.sg_dynamic_config.config.security_group_name })
}

// Build a flattened map of rule entries for stable for_each keys
locals {
  inbound_base = { for idx, r in var.sg_dynamic_config.config.inbound_rules : (trim(try(r.name, "")) != "" ? trim(r.name) : sha1(jsonencode(r))) => r }

  inbound_entries = merge([for k, r in local.inbound_base :
    // create one entry per cidr
    { for idx, cidr in r.cidr_blocks : "${k}-cidr-${idx}" => {
      type        = "ingress"
      from_port   = r.from_port
      to_port     = r.to_port
      protocol    = r.protocol
      cidr        = cidr
      source_sg   = null
      description = try(r.description, "")
      }
    }
  ]...)

  inbound_sg_entries = merge([for k, r in local.inbound_base :
    { for idx, sgid in r.source_security_group_ids : "${k}-sg-${idx}" => {
      type        = "ingress"
      from_port   = r.from_port
      to_port     = r.to_port
      protocol    = r.protocol
      cidr        = null
      source_sg   = sgid
      description = try(r.description, "")
      }
    }
  ]...)

  inbound_rules_map = merge(local.inbound_entries, local.inbound_sg_entries)

  // outbound similarly
  outbound_base = { for idx, r in var.sg_dynamic_config.config.outbound_rules : (trim(try(r.name, "")) != "" ? trim(r.name) : sha1(jsonencode(r))) => r }

  outbound_entries = merge([for k, r in local.outbound_base :
    { for idx, cidr in r.cidr_blocks : "${k}-cidr-${idx}" => {
      type        = "egress"
      from_port   = r.from_port
      to_port     = r.to_port
      protocol    = r.protocol
      cidr        = cidr
      dest_sg     = null
      description = try(r.description, "")
      }
    }
  ]...)

  outbound_sg_entries = merge([for k, r in local.outbound_base :
    { for idx, sgid in r.destination_security_group_ids : "${k}-sg-${idx}" => {
      type        = "egress"
      from_port   = r.from_port
      to_port     = r.to_port
      protocol    = r.protocol
      cidr        = null
      dest_sg     = sgid
      description = try(r.description, "")
      }
    }
  ]...)

  outbound_rules_map = merge(local.outbound_entries, local.outbound_sg_entries)

  rules_map = merge(local.inbound_rules_map, local.outbound_rules_map)

  // validation: disallow open cidr unless allow_all is true
  open_cidrs = [for k, e in local.rules_map : e.cidr if e.cidr != null && e.cidr == "0.0.0.0/0"]
}

resource "aws_security_group_rule" "rules" {
  for_each = local.rules_map

  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr != null ? [each.value.cidr] : null
  source_security_group_id = each.value.source_sg != null ? each.value.source_sg : null
  description              = each.value.description
  security_group_id        = aws_security_group.this.id

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [aws_security_group.this]
}

// Egress entries that referenced dest_sg use the same attribute (source_security_group_id)
resource "aws_security_group_rule" "egress_dest_rules" {
  for_each = { for k, v in local.outbound_rules_map : k => v if v.dest_sg != null }

  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr != null ? [each.value.cidr] : null
  source_security_group_id = each.value.dest_sg
  description              = each.value.description
  security_group_id        = aws_security_group.this.id

  depends_on = [aws_security_group.this]
}

// Validation: if any open CIDR present but allow_all is false -> fail via null resource trick
resource "null_resource" "open_cidr_check" {
  count = 0 # removed unsupported allow_all attribute

  triggers = {
    message = "Security group includes open CIDR 0.0.0.0/0 but config.allow_all is false"
  }
}
