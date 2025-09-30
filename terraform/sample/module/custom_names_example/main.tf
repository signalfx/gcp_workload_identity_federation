module "example_aws_pool_1" {
  source = "../../../modules/workload-identity-pool"

  project_id             = "my-project-id"
  realm_name             = "us0"
  additional_project_ids = ["additional1", "additional2"]
  custom_pool_name       = "custom-pool-name"
  custom_provider_name   = "custom-provider-name"
}

resource "signalfx_gcp_integration" "explicit-projects-integration" {
  name         = "integration1"
  enabled      = true
  poll_rate    = 600
  services     = ["compute"]
  include_list = ["labels"]
  use_metric_source_project_for_quota = true
  auth_method  = "WORKLOAD_IDENTITY_FEDERATION"
  workload_identity_federation_config = module.example_aws_pool_1.credentials_config
  projects {
    selected_project_ids = ["my-project-id", "additional1", "additional2"]
  }
}