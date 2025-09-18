locals {
  enabled = module.this.enabled

  create_security_group = local.enabled && var.security_group_enabled
  create_queue          = local.enabled && var.create_default_queue

  # Fargate compute environment settings
  use_fargate = local.enabled && var.compute_environment_resource == "FARGATE" || var.compute_environment_resource == "FARGATE_SPOT"

  # EC2 compute environment settings
  use_ec2                   = local.enabled && var.compute_environment_resource == "EC2" || var.compute_environment_resource == "SPOT"
  include_launch_template   = local.use_ec2 && (var.launch_template_id != null || var.launch_template_name != null)
  include_ec2_configuration = local.use_ec2 && (var.image_id_override != null || var.image_type != null)
  include_update_policy     = local.use_ec2 && (var.job_execution_timeout_minutes != 60 || var.terminate_jobs_on_update != false)

  # Queue settings
  queue_order = concat([local.env_arn], var.other_compute_environment_queue)

  # Outputs
  security_group_ids = concat(var.security_group_ids, local.create_security_group ? [aws_security_group.batch[0].id] : [])
  env_arn = local.use_fargate ? aws_batch_compute_environment.fargate[0].arn : (
    local.use_ec2 ? aws_batch_compute_environment.ec2[0].arn : null
  )
  cluster_arn = local.use_fargate ? aws_batch_compute_environment.fargate[0].ecs_cluster_arn : (
    local.use_ec2 ? aws_batch_compute_environment.ec2[0].ecs_cluster_arn : null
  )
  queue_arn         = local.create_queue ? aws_batch_job_queue.default[0].arn : null
  security_group_id = local.create_security_group ? aws_security_group.batch[0].id : null
}

module "batch_label" {
  source     = "cloudposse/label/null"
  version    = "~> 0.25.0"
  context    = module.this.context
  attributes = ["batch"]
  enabled    = local.enabled
}

resource "aws_batch_compute_environment" "fargate" {
  count = local.enabled && local.use_fargate ? 1 : 0
  name  = module.batch_label.id
  type  = "MANAGED"
  state = var.env_enabled ? "ENABLED" : "DISABLED"
  tags  = module.batch_label.tags
  compute_resources {
    subnets            = var.subnet_ids
    security_group_ids = local.security_group_ids
    type               = var.compute_environment_resource
    max_vcpus          = var.max_vcpus
  }
}

resource "aws_batch_compute_environment" "ec2" {
  count = local.enabled && local.use_ec2 ? 1 : 0
  name  = module.batch_label.id
  type  = var.env_managed ? "MANAGED" : "UNMANAGED"
  state = var.env_enabled ? "ENABLED" : "DISABLED"
  tags  = module.batch_label.tags
  compute_resources {
    subnets             = var.subnet_ids
    security_group_ids  = local.security_group_ids
    type                = var.compute_environment_resource
    max_vcpus           = var.max_vcpus
    min_vcpus           = var.min_vcpus
    desired_vcpus       = var.desired_vcpus
    ec2_key_pair        = var.ec2_key_pair
    allocation_strategy = var.allocation_strategy
    bid_percentage      = var.compute_environment_resource == "SPOT" ? var.bid_percentage : null
    instance_role       = var.instance_role
    instance_type       = var.instance_type
    placement_group     = var.placement_group
    spot_iam_fleet_role = var.spot_iam_fleet_role
    dynamic "launch_template" {
      for_each = local.include_launch_template ? [1] : []
      content {
        launch_template_id   = var.launch_template_id
        launch_template_name = var.launch_template_name
        version              = var.launch_template_version
      }
    }
    dynamic "ec2_configuration" {
      for_each = local.include_ec2_configuration ? [1] : []
      content {
        image_id_override = var.image_id_override
        image_type        = var.image_type
      }
    }
  }
  dynamic "update_policy" {
    for_each = local.include_update_policy ? [1] : []
    content {
      job_execution_timeout_minutes = var.job_execution_timeout_minutes
      terminate_jobs_on_update      = var.terminate_jobs_on_update
    }
  }
}

module "queue_label" {
  source     = "cloudposse/label/null"
  version    = "~> 0.25.0"
  context    = module.batch_label.context
  attributes = ["queue"]
  enabled    = local.create_queue
}

resource "aws_batch_job_queue" "default" {
  count    = local.create_queue ? 1 : 0
  name     = module.queue_label.id
  priority = 1
  state    = var.default_queue_enabled ? "ENABLED" : "DISABLED"
  dynamic "compute_environment_order" {
    for_each = toset(local.queue_order)
    content {
      order               = index(local.queue_order, compute_environment_order.value) + 1
      compute_environment = compute_environment_order.value
    }
  }
  tags = module.queue_label.tags
}

module "sg_label" {
  source     = "cloudposse/label/null"
  version    = "~> 0.25.0"
  context    = module.batch_label.context
  attributes = ["sg"]
  enabled    = local.create_security_group
}

resource "aws_security_group" "batch" {
  count       = local.create_security_group ? 1 : 0
  name        = module.sg_label.id
  description = "Security group for AWS Batch compute environment"
  vpc_id      = var.vpc_id
  tags        = module.sg_label.tags
}


resource "aws_security_group_rule" "allow_all_egress" {
  count             = local.create_security_group && var.enable_all_egress_rule ? 1 : 0
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.batch[0].id
}

resource "aws_security_group_rule" "allow_icmp_ingress" {
  count             = local.create_security_group && var.enable_icmp_rule ? 1 : 0
  description       = "Allow ping command from anywhere"
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.batch[0].id
}
