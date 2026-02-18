locals {
  backend_config = lookup(local.env, "terraform_backend", null)
}
