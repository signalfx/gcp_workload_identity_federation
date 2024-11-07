module "example_aws_pool_1" {
  source = "../../../modules/workload-identity-pool"

  project_id             = "my-project-id"
  realm_name             = "us0"
  additional_project_ids = ["additional1", "additional2"]
}


resource "signalfx_gcp_integration" "integration1" {
  name         = "integration1"
  enabled      = true
  poll_rate    = 600
  services     = ["compute"]
  include_list = ["labels"]
  auth_method  = "WORKLOAD_IDENTITY_FEDERATION"
  project_wif_configs {
    project_id = "my-project-id"
    wif_config = module.example_aws_pool_1.config_file_content

  }
}

resource "signalfx_gcp_integration" "integration2" {
  name         = "integration2"
  enabled      = true
  poll_rate    = 600
  services     = ["compute"]
  include_list = ["labels"]
  auth_method  = "WORKLOAD_IDENTITY_FEDERATION"
  project_wif_configs {
    project_id = "additional1"
    wif_config = module.example_aws_pool_1.credentials_config
  }
}

resource "signalfx_gcp_integration" "integration3" {
  name         = "integration3"
  enabled      = true
  poll_rate    = 600
  services     = ["compute"]
  include_list = ["labels"]
  auth_method  = "WORKLOAD_IDENTITY_FEDERATION"
  project_wif_configs {
    project_id = "additional2"
    wif_config = module.example_aws_pool_1.credentials_config
  }
}