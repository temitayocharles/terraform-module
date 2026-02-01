variable "environment_file" {
  type        = string
  description = "Path to environment.yaml configuration file"
  
  validation {
    condition     = fileexists(var.environment_file)
    error_message = "Environment file must exist at specified path"
  }
}
