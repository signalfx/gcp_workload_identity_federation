locals {
  is_aws_realm = local.realms_config[var.realm_name]["type"] == "aws"
  pool_id      = length(var.custom_pool_name) > 0 ? var.custom_pool_name : "splunk-identity-pool-${var.realm_name}"
  provider_id  = length(var.custom_provider_name) > 0 ? var.custom_provider_name : "splunk-provider-${var.realm_name}"
  credentials_config = local.is_aws_realm ? jsonencode({
    "universe_domain": "googleapis.com",
    "type": "external_account",
    "audience": "//iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool
.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.aws_provider[0].workload_identity_pool_provider_id}",
    "subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
    "token_url": "https://sts.googleapis.com/v1/token",
    "credential_source": {
      "environment_id": "aws1",
      "region_url": "http://169.254.169.254/latest/meta-data/placement/availability-zone",
      "url": "http://169.254.169.254/latest/meta-data/iam/security-credentials",
      "regional_cred_verification_url": "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
    },
    "token_info_url": "https://sts.googleapis.com/v1/introspect"
  }) : jsonencode({
    "universe_domain": "googleapis.com",
    "type": "external_account",
    "audience": "//iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gcp_provider[0].workload_identity_pool_provider_id}",
    "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
    "token_url": "https://sts.googleapis.com/v1/token",
    "credential_source": {
      "url": "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=//iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gcp_provider[0].workload_identity_pool_provider_id}",
      "headers": {
        "Metadata-Flavor": "Google"
      }
    },
    "token_info_url": "https://sts.googleapis.com/v1/introspect"
  })
}

resource "google_iam_workload_identity_pool" "identity_pool" {
  project                   = var.project_id
  workload_identity_pool_id = local.pool_id
}


resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  count                              = local.is_aws_realm ? 1 : 0
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = local.provider_id
  attribute_condition                = "attribute.aws_role == \"${local.realms_config[var.realm_name]["role"]}\""

  aws {
    account_id = split(":", local.realms_config[var.realm_name]["role"])[4]
  }
}

resource "google_iam_workload_identity_pool_provider" "gcp_provider" {
  count                     = local.is_aws_realm ? 0 : 1
  project                   = var.project_id
  workload_identity_pool_id = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  attribute_mapping         = {
    "google.subject" = "assertion.email"
  }
  attribute_condition                = "google.subject == \"${local.realms_config[var.realm_name]["sa_email"]}\""
  workload_identity_pool_provider_id = local.provider_id
  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_project_iam_member" "member" {
  for_each = {
    for project_and_role in flatten([
      for project_id in concat(var.additional_project_ids, [var.project_id]) : [
        for role in var.roles : {
          project_id = project_id
          role       = role
        }
      ]
    ]) :
    "${project_and_role.project_id}:${project_and_role.role}" => project_and_role
  }
  project = each.value.project_id
  role    = each.value.role
  member  = local.is_aws_realm ? "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${local.realms_config[var.realm_name]["role"]}" : "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${local.realms_config[var.realm_name]["sa_email"]}"
}

resource "google_folder_iam_member" "member" {
  for_each = {
    for folder_and_role in flatten([
      for folder in var.folder_ids : [
        for role in var.roles : {
          folder = folder
          role   = role
        }
      ]
    ]) :
    "${folder_and_role.folder}:${folder_and_role.role}" => folder_and_role
  }
  folder = each.value.folder
  role   = each.value.role
  member = local.is_aws_realm ? "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${local.realms_config[var.realm_name]["role"]}" : "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${local.realms_config[var.realm_name]["sa_email"]}"
}

output "credentials_config" {
  depends_on = [google_project_iam_member.member]
  value = local.credentials_config
}