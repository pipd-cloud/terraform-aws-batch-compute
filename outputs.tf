output "compute_environment_arn" {
  description = "Batch Compute Environment ARN"
  value       = local.env_arn
}

output "job_queue_arn" {
  description = "Batch Compute Queue ARN"
  value       = local.queue_arn
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = local.cluster_arn
}
