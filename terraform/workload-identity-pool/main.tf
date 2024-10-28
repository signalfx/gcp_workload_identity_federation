locals {
  is_aws_realm = local.realms_config[var.realm_name]["type"] == "aws"
  pool_id      = length(var.custom_pool_name) > 0 ? var.custom_pool_name : "splunk-identity-pool-${var.realm_name}"
  provider_id  = length(var.custom_provider_name) > 0 ? var.custom_provider_name : "splunk-provider-${var.realm_name}"

}

resource "google_iam_workload_identity_pool" "identity_pool" {
  project                   = var.project_id
  workload_identity_pool_id = local.pool_id
}


resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  count                              = local.is_aws_realm ? 1 : 0
  workload_identity_pool_id          = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = local.provider_id
  attribute_condition                = "attribute.aws_role == \"${local.realms_config[var.realm_name]["role"]}\""

  aws {
    account_id = split(":", local.realms_config[var.realm_name]["role"])[4]
  }
}

resource "google_iam_workload_identity_pool_provider" "gcp_provider" {
  count                     = local.is_aws_realm ? 0 : 1
  workload_identity_pool_id = google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id
  attribute_mapping         = {
    "google.subject" = "assertion.email"
  }
  attribute_condition  = "google.subject == \"${local.realms_config[var.realm_name]["sa_email"]}\""
  workload_identity_pool_provider_id = local.provider_id
  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_project_iam_binding" "binding_main" {
  project = var.project_id
  role    = var.role
  members = [
    local.is_aws_realm ?
    "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${local.realms_config[var.realm_name]["role"]}" :
    "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${local.realms_config[var.realm_name]["sa_email"]}"
  ]
}

resource "google_project_iam_binding" "binding_additional" {
  for_each = toset(var.additional_project_ids)
  project  = each.value
  role     = var.role
  members  = [
    local.is_aws_realm ?
    "principalSet://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/attribute.aws_role/${local.realms_config[var.realm_name]["role"]}" :
    "principal://iam.googleapis.com/projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/subject/${local.realms_config[var.realm_name]["sa_email"]}"
  ]
}

resource "null_resource" "generate_credentials_aws" {
  count = local.is_aws_realm ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
    mkdir -p ./out
    echo "Issuing gcloud command to create config file at path ./out/wif-credentials-${var.realm_name}-${var.project_id}.json"
    gcloud iam workload-identity-pools create-cred-config \
    projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.aws_provider[0].workload_identity_pool_provider_id} \
    --aws \
    --output-file=./out/wif-credentials-${var.realm_name}-${var.project_id}.json
    EOT

  }

  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "generate_credentials_gcp" {
  count = local.is_aws_realm ? 0 : 1
  provisioner "local-exec" {
    command = <<EOT
    mkdir -p ./out
    echo "Issuing gcloud command to create config file at path ./out/wif-credentials-${var.realm_name}-${var.project_id}.json"
    gcloud iam workload-identity-pools create-cred-config \
    projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gcp_provider[0].workload_identity_pool_provider_id} \
   --credential-source-url=http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=projects/${data.google_project.selected.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.identity_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gcp_provider[0].workload_identity_pool_provider_id} \
    --credential-source-headers=Metadata-Flavor=Google \
    --output-file=./out/wif-credentials-${var.realm_name}-${var.project_id}.json
    EOT

  }
  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "generated_aws_credentials" {
  count      = local.is_aws_realm ? 1 : 0
  depends_on = [
    null_resource.generate_credentials_aws, google_project_iam_binding.binding_additional, google_project_iam_binding.binding_main
  ]
  filename   = "./out/wif-credentials-${var.realm_name}-${var.project_id}.json"
}

data "local_file" "generated_gcp_credentials" {
  count      = local.is_aws_realm ? 0 : 1
  depends_on = [
    null_resource.generate_credentials_gcp, google_project_iam_binding.binding_additional, google_project_iam_binding.binding_main
  ]
  filename   = "./out/wif-credentials-${var.realm_name}-${var.project_id}.json"
}
output "credentials_file_content" {
  value = local.is_aws_realm ? data.local_file.generated_aws_credentials[0].content : data.local_file.generated_gcp_credentials[0].content
}