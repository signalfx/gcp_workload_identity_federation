module "example_aws_pool_1" {
  source = "../../../modules/workload-identity-pool"

  project_id             = "my-project-id"
  realm_name             = "us0"
  folder_ids             = ["folder1", "folder2"]
}


resource "signalfx_gcp_integration" "multiproject_integration" {
  name         = "integration1"
  enabled      = true
  poll_rate    = 600
  services     = ["compute"]
  include_list = ["labels"]
  use_metric_source_project_for_quota = true
  auth_method  = "WORKLOAD_IDENTITY_FEDERATION"
  workload_identity_federation_config = module.example_aws_pool_1.credentials_config
  projects {
    sync_mode = "ALL_REACHABLE"
  }
}