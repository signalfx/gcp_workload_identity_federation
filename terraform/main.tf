module "example_aws_pool_1" {
  source = "./workload-identity-pool"

  project_id     = "molten-enigma-184614"
  realm_name     = "aws5"
 additional_project_ids = ["lab1-env-716"]
}

module "example_gcp_pool_1" {
  source = "./workload-identity-pool"

  project_id     = "molten-enigma-184614"
  realm_name     = "gcp5"

}