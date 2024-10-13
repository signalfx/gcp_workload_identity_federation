variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "additional_project_ids" {
  description = "List of additional project IDs for IAM policy binding"
  type        = list(string)
  default     = []
}

variable "realm_name" {
  description = "The Splunk Observability realm. It can be found at: User Profile -> Organizations"
  type        = string
}

variable "role" {
  description = "Specify role which will be granted"
  type        = string
  default = "roles/viewer"
}


variable "aws_realms" {
  description = "Map of AWS realms with associated role ARNs."
  type = map(object({
    role_arn = string
  }))
  default = {
    aws5 = { role_arn = "arn:aws:sts::134183635603:assumed-role/eks-lab0-cloud-metric-syncer" }
  }
}

variable "gcp_realms" {
  description = "Map of GCP realms with associated service account emails."
  type = map(object({
    sa_email = string
  }))
  default = {
    gcp5 = { sa_email = "imm-cloud-metric-sync-non-aws@lab1-env-716.iam.gserviceaccount.com" }
  }
}

data "google_project" "selected" {
  project_id = var.project_id
}