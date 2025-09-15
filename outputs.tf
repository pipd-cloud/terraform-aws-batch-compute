output "exec_role_name" {
  description = "ECS Task exec role name"
  value       = local.exec_role_name
}

output "exec_role_arn" {
  description = "ECS Task exec role ARN"
  value       = local.exec_role_arn
}

output "exec_role_policy_arn_map" {
  description = "Map of ECS Task exec role policy ARNs"
  value       = local.exec_role_policy_arn_map
}

output "exec_role_id" {
  description = "ECS Task exec role id"
  value       = local.exec_role_id
}


output "environment_arn" {
  description = "Batch Compute Environment ARN"
  value       = local.env_arn
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = local.cluster_arn
}

output "queue_arn" {
  description = "Batch Compute Queue ARN"
  value       = local.queue_arn
}
