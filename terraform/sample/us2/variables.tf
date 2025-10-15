variable "project_id" {
  description = "GCP project ID."
  type        = string
  default = "molten-enigma-184614"
}

variable "pool_name" {
  description = "GCP WIF pool name."
  type        = string
  default     = "splunk-identity-pool"
}

variable "provider_name" {
  description = "GCP WIF provider name."
  type        = string
  default     = "splunk-provider"
}

variable "folder" {
  description = "Id of a folder containing synced projects"
  type        = string
}

variable "additional_project_ids" {
  description = "List of additional project IDs for IAM policy binding."
  type = set(string)
}

variable "roles" {
  description = "Role which will be granted."
  type        = set(string)
  default     = ["roles/viewer", "roles/serviceusage.serviceUsageConsumer"]
}

variable "sa_email" {
  description = "Email of  of Splunk observability Service Account, can be found in a doc"
  type        = string
  default     = "splunk-observability@us2-env-181.iam.gserviceaccount.com"
}
