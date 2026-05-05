output "app_url"               { value = "http://${module.ecs.alb_dns_name}" }
output "ecr_repository_url"   { value = module.ecr.repository_url }
output "ecs_cluster_name"     { value = module.ecs.cluster_name }
output "ecs_service_name"     { value = module.ecs.service_name }
output "cloudwatch_log_group" { value = module.cloudwatch.log_group_name }
output "dashboard_url"        { value = module.cloudwatch.dashboard_url }
output "vpc_id"               { value = module.vpc.vpc_id }