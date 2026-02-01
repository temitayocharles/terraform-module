
variable "rds_config" {
  description = <<DESC
RDS configuration object.

enabled: Set to true to enable creation of the RDS instance. If false, no RDS resources will be created.

engine: The database engine to use (e.g., 'postgres', 'mysql').
engine_version: The version of the database engine (e.g., '13' for Postgres).
instance_class: The instance class for the RDS instance (e.g., 'db.t3.medium').
allocated_storage: The amount of storage (in GB) to allocate for the database.
subnet_ids: List of subnet IDs for the DB subnet group. Should be private subnets.
security_group_ids: List of security group IDs to associate with the RDS instance.
allowed_source_cidr: List of CIDR blocks allowed to connect to the DB (e.g., for app servers).
allowed_source_security_group_ids: List of security group IDs allowed to connect to the DB.
rotation_lambda_arn: ARN of the rotation Lambda function, if using password rotation.
rotation_days: Number of days between password rotations (if enabled).
vpc_id: VPC ID for the RDS instance. Can be auto-populated from remote state or set manually.
require_vpc_for_sg: If true, ensures security groups are created in the specified VPC.
username: Master username for the database. Should be managed securely.
password: Master password for the database. Should be managed securely.
create_secret: If true, creates a Secrets Manager secret for DB credentials.
secret_name: Name of the secret in Secrets Manager (if create_secret is true).
db_name: Name of the database to create.
skip_final_snapshot: If true, skips final snapshot on DB deletion (not recommended for production).
DESC
  type = object({
    enabled                           = bool
    engine                            = string
    engine_version                    = string
    instance_class                    = string
    allocated_storage                 = number
    subnet_ids                        = list(string)
    security_group_ids                = list(string)
    allowed_source_cidr               = list(string)
    allowed_source_security_group_ids = list(string)
    rotation_lambda_arn               = string
    rotation_days                     = number
    vpc_id                            = string
    require_vpc_for_sg                = bool
    username                          = string
    password                          = string
    create_secret                     = bool
    secret_name                       = string
    db_name                           = string
    skip_final_snapshot               = bool
  })
}
