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
    us0 = { role_arn = "arn:aws:sts::134183635603:assumed-role/us0-splunk-observability" }
    us1 = { role_arn = "arn:aws:sts::562691491210:assumed-role/us1-splunk-observability" }
    jp0 = { role_arn = "arn:aws:sts::947592474007:assumed-role/jp0-splunk-observability" }
    au0 = { role_arn = "arn:aws:sts::642047998396:assumed-role/au0-splunk-observability" }
    eu0 = { role_arn = "arn:aws:sts::214014584948:assumed-role/eu0-splunk-observability" }
    eu1 = { role_arn = "arn:aws:sts::797571435910:assumed-role/eu1-splunk-observability" }
    eu2 = { role_arn = "arn:aws:sts::417715959474:assumed-role/eu2-splunk-observability" }
  }
}

variable "gcp_realms" {
  description = "Map of GCP realms with associated service account emails."
  type = map(object({
    sa_email = string
  }))
  default = {
    us2 = { sa_email = "splunk-observability@us2-env-181.iam.gserviceaccount.com" }
  }
}



data "google_project" "selected" {
  project_id = var.project_id
}