variable "vpc_id" {
  type        = string
  description = "The VPC ID where resources are created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs on which the Batch compute environment will be created"
  default     = null
}

variable "security_group_enabled" {
  type        = bool
  description = "Whether to create a security group for the compute environment."
  default     = true
}

variable "enable_all_egress_rule" {
  type        = bool
  description = "A flag to enable/disable adding the all ports egress rule to the service security group"
  default     = true
}

variable "enable_icmp_rule" {
  type        = bool
  description = "Specifies whether to enable ICMP on the service security group"
  default     = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional security groups to attach to the compute environment"
  default     = []
}

# Compute
variable "compute_environment_resource" {
  description = "The type of compute resource to use for the Batch compute environment. Valid values are EC2, SPOT, FARGATE, and FARGATE_SPOT."
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["EC2", "SPOT", "FARGATE", "FARGATE_SPOT"], var.compute_environment_resource)
    error_message = "compute_environment_resource must be one of 'EC2', 'SPOT', 'FARGATE', or 'FARGATE_SPOT'."
  }
}

variable "other_compute_environment_queue" {
  description = "A list of additional compute environments to add to the default queue."
  type        = list(string)
  default     = []
}

variable "max_vcpus" {
  description = "The maximum number of vCPUs for the Batch compute environment. Defaults to 16."
  type        = number
  default     = 16
}

variable "min_vcpus" {
  description = "The minimum number of vCPUs that an environment should maintain. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = number
  default     = 0
}

variable "desired_vcpus" {
  description = "The desired number of vCPUs in the compute environment. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = number
  default     = 0
}

variable "ec2_key_pair" {
  description = "The EC2 key pair that is used for instances launched in the compute environment. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  default     = ""
}

variable "allocation_strategy" {
  description = "The allocation strategy to use for the compute environment. This parameter is only used for env_resource types of SPOT."
  type        = string
  default     = "BEST_FIT_PROGRESSIVE"
  validation {
    condition     = contains(["BEST_FIT", "BEST_FIT_PROGRESSIVE", "SPOT_CAPACITY_OPTIMIZED"], var.allocation_strategy)
    error_message = "allocation_strategy must be one of 'BEST_FIT', 'BEST_FIT_PROGRESSIVE', or 'SPOT_CAPACITY_OPTIMIZED'."
  }
}

variable "bid_percentage" {
  description = "The maximum percentage that a Spot Instance price can be when compared with the On-Demand price for that instance type before instances are launched. This parameter is only used for env_resource types of SPOT."
  type        = number
  default     = 100
}

variable "instance_role" {
  description = "The Amazon ECS instance profile applied to Amazon EC2 instances in a compute environment. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "instance_type" {
  description = "The instance type or types to use for the compute environment. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = list(string)
  default     = []
}

variable "launch_template_id" {
  description = "The ID of the launch template to use for your compute resources. This parameter is optional. If it is not provided, and neither launch_template_name nor ec2_configuration is provided, the default launch template for the account and Region is used. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "launch_template_name" {
  description = "The name of the launch template to use for your compute resources. This parameter is optional. If it is not provided, and neither launch_template_id nor ec2_configuration is provided, the default launch template for the account and Region is used. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "launch_template_version" {
  description = "The version number of the launch template to use for your compute resources. If no version is specified, the default version will be used. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "image_id_override" {
  description = "The AMI ID used for instances launched in the compute environment. This parameter overrides the AMI ID that is determined by Amazon ECS for the compute environment. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "image_type" {
  description = "The type of Amazon Machine Image (AMI) that is used for instances launched in the compute environment. This parameter determines whether the AMI ID or the launch template is used to determine the AMI for instances launched in the compute environment. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "placement_group" {
  description = "The Amazon EC2 placement group to associate with your compute resources. This parameter is only used for env_resource types of EC2 and SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "spot_iam_fleet_role" {
  description = "The Amazon Resource Name (ARN) of the Amazon EC2 Spot Fleet IAM role applied to a SPOT compute environment. This parameter is only used for env_resource types of SPOT."
  type        = string
  nullable    = true
  default     = null
}

variable "job_execution_timeout_minutes" {
  description = "The maximum amount of time, in minutes, that a job can run. If the job attempts to run for longer than this time, AWS Batch terminates the job. This parameter is used in the update_policy block."
  type        = number
  default     = 60
}

variable "terminate_jobs_on_update" {
  description = "Indicates whether to terminate jobs when the compute environment is updated. This parameter is used in the update_policy block."
  type        = bool
  default     = false
}

variable "env_managed" {
  description = "Whether to create a managed or unmanaged Batch compute environment. Defaults to true (managed)."
  type        = bool
  default     = true
}

variable "env_enabled" {
  description = "Whether the Batch compute environment should be enabled. Defaults to true."
  type        = bool
  default     = true
}

# Batch queue
variable "create_default_queue" {
  description = "Whether to create a default job queue"
  type        = bool
  default     = true
}

variable "default_queue_enabled" {
  description = "Whether the default job queue should be enabled."
  type        = bool
  default     = true
}

