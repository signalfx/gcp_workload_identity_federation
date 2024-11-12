terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    signalfx = {
      source = "splunk-terraform/signalfx"
    }
  }
  required_version = ">= 0.13.0"
}

provider "google" {
  project = "<project-id>"
}

provider signalfx {
  auth_token = "<token>"
  api_url    = "https://api.us2.signalfx.com"
}
locals {
  credentials_config = jsonencode({
    "universe_domain" : "googleapis.com",
    "type" : "external_account",
    "audience" : "//iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gcp_provider.workload_identity_pool_provider_id}",
    "subject_token_type" : "urn:ietf:params:oauth:token-type:jwt",
    "token_url" : "https://sts.googleapis.com/v1/token",
    "credential_source" : {
      "url" : "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=//iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gcp_provider.workload_identity_pool_provider_id}",
      "headers" : {
        "Metadata-Flavor" : "Google"
      }
    },
    "token_info_url" : "https://sts.googleapis.com/v1/introspect"
  })
}

data "google_project" "selected" {
  project_id = var.project_id
}

resource "google_iam_workload_identity_pool" "identity_pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_name
}


resource "google_iam_workload_identity_pool_provider" "gcp_provider" {
  workload_identity_pool_id = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  attribute_mapping         = {
    "google.subject" = "assertion.email"
  }
  attribute_condition                = "google.subject == \"${var.sa_email}\""
  workload_identity_pool_provider_id = var.provider_name
  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_project_iam_member" "member" {
  for_each = toset(concat(var.additional_project_ids, [var.project_id]))
  project  = each.value
  role     = var.role
  member   = "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${var.sa_email}"
}

resource "signalfx_gcp_integration" "example_integration" {
  name         = "Using WIF"
  enabled      = true
  poll_rate    = 600
  include_list = ["labels"]
  auth_method  = "WORKLOAD_IDENTITY_FEDERATION"
  project_wif_configs {
    project_id = var.project_id
    wif_config = local.credentials_config

  }
}