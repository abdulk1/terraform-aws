project_name = "enterprise-webapp"
environment  = "prod"
aws_region   = "us-east-1"

vpc_cidr           = "10.30.0.0/16"
az_count           = 3
single_nat_gateway = false

kubernetes_version   = "1.33"
auto_mode_node_pools = ["system", "general-purpose"]

endpoint_public_access       = false
endpoint_public_access_cidrs = ["0.0.0.0/0"]

enable_cluster_creator_admin_permissions = true
cluster_admin_principal_arns             = []
cluster_viewer_principal_arns            = []

cluster_log_retention_days  = 365
enable_vpc_flow_logs        = true
vpc_flow_log_retention_days = 365

deletion_protection  = true
upgrade_support_type = "STANDARD"
enable_zonal_shift   = true

tags = {
  CostCenter = "platform"
  Workload   = "web"
}
