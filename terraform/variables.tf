# variables.tf

variable "realm_name" {
  description = "The realm to be used for the Workload Identity Federation."
  type        = string
}

variable "aws_realms" {
  description = "Map of AWS realms with associated role ARNs."
  type = map(object({
    role_arn = string
  }))
  default = {
    aws-realm1 = { role_arn = "arn:aws:iam::123456789012:role/example-role1" }
    aws-realm2 = { role_arn = "arn:aws:iam::987654321098:role/example-role2" }
  }
}

variable "gcp_realms" {
  description = "Map of GCP realms with associated service account emails."
  type = map(object({
    sa_email = string
  }))
  default = {
    gcp-realm1 = { sa_email = "example-sa1@project-id.iam.gserviceaccount.com" }
    gcp-realm2 = { sa_email = "example-sa2@project-id.iam.gserviceaccount.com" }
  }
}
