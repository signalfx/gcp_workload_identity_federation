# main.tf

locals {
  is_aws_realm = contains(keys(var.aws_realms), var.realm_name)
}

resource "google_iam_workload_identity_pool" "identity_pool" {
  project  = var.project_id
  workload_identity_pool_id = "splunk-identity-pool-${var.realm_name}"
}


resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  count                = local.is_aws_realm ? 1 : 0
  workload_identity_pool_id          = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "splunk-provider-${var.realm_name}"
  attribute_condition                = "assertion.aws_role == \"${var.aws_realms[var.realm_name].role_arn}\""
  attribute_mapping                  = {
    "google.subject" = "assertion.aws_role"
  }
  aws {
    account_id = split(":", var.aws_realms[var.realm_name].role_arn)[4]
  }
}

resource "google_iam_workload_identity_pool_provider" "gcp_provider" {
  count                = local.is_aws_realm ? 0 : 1
  workload_identity_pool_id = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  attribute_mapping    = {
    "google.subject" = "assertion.email"
  }
  attribute_condition  = "assertion.email == \"${var.gcp_realms[var.realm_name].sa_email}\""
  workload_identity_pool_provider_id = "splunk-provider-${var.realm_name}"
  oidc {
    issuer_uri        = "https://accounts.google.com"
  }
}

resource "google_project_iam_binding" "binding_main" {
  project  = var.project_id
  role    = var.role
  members = [
    local.is_aws_realm ?
    "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${var.aws_realms[var.realm_name].role_arn}" :
    "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${var.gcp_realms[var.realm_name].sa_email}"
  ]
}

resource "google_project_iam_binding" "binding_additional" {
  for_each = toset(var.additional_project_ids)
  project  = each.value
  role    = var.role
  members = [
    local.is_aws_realm ?
    "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${var.aws_realms[var.realm_name].role_arn}" :
    "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${var.gcp_realms[var.realm_name].sa_email}"
  ]
}

