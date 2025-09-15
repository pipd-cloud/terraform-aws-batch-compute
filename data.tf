data "aws_iam_policy" "exec" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "exec_trust" {
  count = local.create_exec_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
