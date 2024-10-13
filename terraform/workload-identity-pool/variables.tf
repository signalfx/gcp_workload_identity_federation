variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "custom_pool_name" {
  description = "GCP WIF pool name."
  type        = string
  default     = ""
}

variable "custom_provider_name" {
  description = "GCP WIF provider name."
  type        = string
  default     = ""
}

variable "additional_project_ids" {
  description = "List of additional project IDs for IAM policy binding."
  type        = list(string)
  default     = []
}

variable "realm_name" {
  description = "The Splunk Observability realm. It can be found at: User Profile -> Organizations".
  type        = string
}

variable "role" {
  description = "Role which will be granted."
  type        = string
  default     = "roles/viewer"
}

variable "custom_realms_config_path" {
  description = "Path of realms config"
  type        = string
default = ""
}

data "google_project" "selected" {
  project_id = var.project_id
}

locals {
  realms_config_path =  length(var.custom_realms_config_path) > 0 ? var.custom_realms_config_path : "${path.module}/realms.json"
  realms_config      = jsondecode(file(local.realms_config_path))
}