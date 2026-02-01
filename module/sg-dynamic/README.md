# sg-dynamic module

Purpose: reusable security-group module that accepts a structured `config` object and creates AWS security group + rules.

Schema (config object):

- `security_group_name` (string) - name of SG
- `security_group_description` (string) - description
- `tags` (map(string)) - tags to apply
- `allow_all` (bool) - must be set `true` to allow rules that include `0.0.0.0/0`
- `inbound_rules` (list(object)) each with:
  - `name` (optional string)
  - `from_port` (number)
  - `to_port` (number)
  - `protocol` (string)
  - `cidr_blocks` (optional list(string))
  - `source_security_group_ids` (optional list(string))
  - `description` (optional string)
- `outbound_rules` (list(object)) similar to inbound; use `destination_security_group_ids` to reference other SGs

Notes & Best practices:
- The module requires callers to explicitly opt-in to open CIDR (`0.0.0.0/0`) by setting `allow_all = true`.
- Rule resources are created with stable keys derived from a hash of rule attributes, so updates map cleanly.
- The module supports multiple `cidr_blocks` and multiple source/destination security-group IDs; it creates one rule per CIDR or per SG ID.
- Set `create_before_destroy = true` at module level only when you understand the side-effects in your account.


## Example usage

Configuration for this module is now managed via a single object in `environment.yaml` (see `sg_dynamic_example` block):

```yaml
sg_dynamic_example:
  vpc_id: "<your-vpc-id>"
  create_before_destroy: false
  config:
    security_group_name: "example-sg"
    security_group_description: "Example security group"
    tags:
      Name: "example-sg"
      Project: "ultimate-cicd-devops"
      Environment: "dev"
    allow_all: false
    inbound_rules: []
    outbound_rules: []
```

Reference and update `environment.yaml` for all configuration. No .tfvars or example files are required.
