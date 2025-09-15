locals {
  enabled = module.this.enabled

  create_exec_role      = local.enabled && var.exec_role_enabled
  create_security_group = local.enabled && var.security_group_enabled
  create_queue          = local.enabled && var.default_queue_enabled

  use_fargate               = local.enabled && var.env_resource == "FARGATE" || var.env_resource == "FARGATE_SPOT"
  use_ec2                   = local.enabled && var.env_resource == "EC2" || var.env_resource == "SPOT"
  include_launch_template   = local.use_ec2 && (var.launch_template_id != null || var.launch_template_name != null)
  include_ec2_configuration = local.use_ec2 && (var.image_id_override != null || var.image_type != null)
  include_update_policy     = local.use_ec2 && (var.job_execution_timeout_minutes != 60 || var.terminate_jobs_on_update != false)

  # Outputs
  security_group_ids = concat(var.security_group_ids, local.create_security_group ? [aws_security_group.batch[0].id] : [])
  env_arn = local.use_fargate ? aws_batch_compute_environment.fargate[0].arn : (
    local.use_ec2 ? aws_batch_compute_environment.ec2[0].arn : null
  )
  cluster_arn = local.use_fargate ? aws_batch_compute_environment.fargate[0].ecs_cluster_arn : (
    local.use_ec2 ? aws_batch_compute_environment.ec2[0].ecs_cluster_arn : null
  )
  exec_role_name = local.create_exec_role ? aws_iam_role.exec[0].name : null
  exec_role_arn  = local.create_exec_role ? aws_iam_role.exec[0].arn : null
  exec_role_id   = local.create_exec_role ? aws_iam_role.exec[0].unique_id : null
  exec_role_policy_arn_map = local.create_exec_role ? merge(
    { for k, v in aws_iam_policy.exec_custom : k => v.arn },
    var.exec_policy_arns_map,
  ) : {}
  queue_arn = local.create_queue ? aws_batch_job_queue.default[0].arn : null
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
    type               = var.env_resource
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
    type                = var.env_resource
    max_vcpus           = var.max_vcpus
    min_vcpus           = var.min_vcpus
    desired_vcpus       = var.desired_vcpus
    ec2_key_pair        = var.ec2_key_pair
    allocation_strategy = var.allocation_strategy
    bid_percentage      = var.env_resource == "SPOT" ? var.bid_percentage : null
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
  state    = "ENABLED"
  compute_environment_order {
    order               = 1
    compute_environment = local.env_arn
  }
  tags = module.queue_label.tags
}


module "exec_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  enabled    = local.create_exec_role
  attributes = ["exec"]
  context    = module.this.context
}

resource "aws_iam_role" "exec" {
  count                = local.create_exec_role ? 1 : 0
  name                 = module.exec_label.id
  assume_role_policy   = data.aws_iam_policy_document.exec_trust[0].json
  permissions_boundary = var.permissions_boundary
  tags                 = module.exec_label.tags
}

resource "aws_iam_role_policy" "exec" {
  count  = local.create_exec_role ? 1 : 0
  name   = module.exec_label.id
  policy = data.aws_iam_policy.exec.arn
  role   = aws_iam_role.exec[0].id
}

resource "aws_iam_policy" "exec_custom" {
  for_each = local.create_exec_role ? var.exec_policy_json_map : {}
  name     = "${module.exec_label.id}-${each.key}"
  policy   = each.value
  tags     = module.exec_label.tags
}

resource "aws_iam_role_policy_attachment" "exec_custom" {
  for_each   = local.create_exec_role ? aws_iam_policy.exec_custom : {}
  policy_arn = each.value.arn
  role       = aws_iam_role.exec[0].id
}

resource "aws_iam_role_policy_attachment" "exec" {
  for_each   = local.create_exec_role ? var.exec_policy_arns_map : {}
  policy_arn = each.value
  role       = aws_iam_role.exec[0].id
}

resource "aws_security_group" "batch" {
  count       = local.create_security_group ? 1 : 0
  vpc_id      = var.vpc_id
  name        = module.batch_label.id
  description = var.security_group_description
  tags        = module.batch_label.tags

  lifecycle {
    create_before_destroy = true
  }
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
