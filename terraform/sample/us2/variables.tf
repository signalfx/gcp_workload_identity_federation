variable "project_id" {
  description = "GCP project ID."
  type        = string
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

variable "additional_project_ids" {
  description = "List of additional project IDs for IAM policy binding."
  type        = list(string)
  default     = []
}

variable "role" {
  description = "Role which will be granted."
  type        = string
  default     = "roles/viewer"
}

variable "sa_email" {
  description = "Email of  of Splunk observability Service Account, can be found in a doc"
  type        = string
}
