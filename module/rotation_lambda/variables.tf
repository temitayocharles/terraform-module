variable "rotation_lambda_config" {
  description = <<DESC
Rotation Lambda configuration object.

enabled: Set to true to enable creation of the rotation Lambda function. If false, no Lambda resources will be created.
name: Name for the Lambda function. Used for resource naming and tagging.
runtime: The runtime environment for the Lambda function (e.g., "nodejs14.x").
handler: The function entry point in your code (e.g., "index.handler").
timeout: The amount of time that Lambda allows a function to run before stopping it (in seconds).
memory_size: The amount of memory allocated to the function (in MB).
DESC
  type = object({
    enabled     = bool
    name        = string
    runtime     = string
    handler     = string
    timeout     = number
    memory_size = number
  })
}
