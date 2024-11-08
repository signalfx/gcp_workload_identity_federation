terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    signalfx = {
      source  = "splunk-terraform/signalfx"
    }
  }
  required_version = ">= 0.13.0"
}


provider "google" {
  project     = var.project_id
}

provider signalfx {
  auth_token = "<token>"
  api_url = "<url>"
}
locals{
  credentials_config = jsonencode({
    "universe_domain": "googleapis.com",
    "type": "external_account",
    "audience": "//iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.provier.workload_identity_pool_provider_id}",
    "subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
    "token_url": "https://sts.googleapis.com/v1/token",
    "credential_source": {
      "environment_id": "aws1",
      "region_url": "http://169.254.169.254/latest/meta-data/placement/availability-zone",
      "url": "http://169.254.169.254/latest/meta-data/iam/security-credentials",
      "regional_cred_verification_url": "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
    },
    "token_info_url": "https://sts.googleapis.com/v1/introspect"
  })
}

data "google_project" "selected" {
  project_id = var.project_id
}

resource "google_iam_workload_identity_pool" "identity_pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_name
}


resource "google_iam_workload_identity_pool_provider" "provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_name
  attribute_condition                = "attribute.aws_role == \"${var.splunk_role_arn}\""

  aws {
    account_id = split(":", var.splunk_role_arn)[4]
  }
}

resource "google_project_iam_member" "member" {
  for_each = toset(concat(var.additional_project_ids, [var.project_id]))
  project = each.value
  role    = var.role
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${var.splunk_role_arn}"
}

resource "signalfx_gcp_integration" "example_integration" {
  name = "Using WIF"
  enabled = true
  poll_rate = 600
  include_list = ["labels"]
  auth_method = "WORKLOAD_IDENTITY_FEDERATION"
  project_wif_configs {
    project_id = var.project_id
    wif_config = local.credentials_config

  }
}