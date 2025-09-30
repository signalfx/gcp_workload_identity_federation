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

variable "splunk_role_arn" {
  description = "ARN of Splunk observability AWS role, it can be found in documentation"
  type        = string
  default     = "arn:aws:sts::134183635603:assumed-role/us0-splunk-observability"
}
