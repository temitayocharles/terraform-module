variable "sg_dynamic_config" {
  description = <<DESC
Dynamic Security Group configuration object.

vpc_id: VPC ID where the security group will be created. Can be auto-populated from remote state or set manually.
create_before_destroy: If true, creates a new SG before destroying the old one (zero-downtime replacement).
config: Object containing security group details:
  - security_group_name: Name for the security group (user-defined or generated)
  - security_group_description: Description for the security group
  - tags: Map of tags to apply to the security group
  - allow_all: If true, allows all traffic (not recommended for production)
  - inbound_rules: List of inbound rule objects (user-defined or templated)
  - outbound_rules: List of outbound rule objects (user-defined or templated)
DESC
  type = object({
    vpc_id                = string
    create_before_destroy = bool
    config = object({
      security_group_name        = string
      security_group_description = string
      tags                       = map(string)
      allow_all                  = bool
      inbound_rules = list(object({
        name                      = optional(string)
        from_port                 = number
        to_port                   = number
        protocol                  = string
        cidr_blocks               = optional(list(string), [])
        source_security_group_ids = optional(list(string), [])
        description               = optional(string, "")
      }))
      outbound_rules = list(object({
        name                           = optional(string)
        from_port                      = number
        to_port                        = number
        protocol                       = string
        cidr_blocks                    = optional(list(string), [])
        destination_security_group_ids = optional(list(string), [])
        description                    = optional(string, "")
      }))
    })
  })

  validation {
    condition     = var.sg_dynamic_config.config.security_group_name != ""
    error_message = "Provide a config object with a non-empty security_group_name. See module/sg-dynamic/README.md for details."
  }
}
