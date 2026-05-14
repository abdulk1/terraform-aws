project_name = "hive-mvp"
environment  = "dev"
aws_region   = "us-east-1"

vpc_cidr = "10.10.0.0/16"
az_count = 3

kubernetes_version   = "1.35"
auto_mode_node_pools = ["system", "general-purpose"]

enable_cluster_creator_admin_permissions = true
cluster_admin_principal_arns             = []
cluster_viewer_principal_arns            = []

cluster_log_retention_days  = 30
enable_vpc_flow_logs        = true
vpc_flow_log_retention_days = 30

deletion_protection  = false
upgrade_support_type = "STANDARD"
enable_zonal_shift   = true

# Enable after the internal EKS Auto Mode ALB listener exists.
enable_http_api_gateway            = false
internal_alb_listener_arn          = null
internal_alb_security_group_id     = null
internal_alb_listener_port         = 443
http_api_authorization_type        = "AWS_IAM"
http_api_access_log_retention_days = 30

tags = {
  CostCenter = "platform"
  Workload   = "web"
}
