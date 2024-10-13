terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }

  required_version = ">= 0.13.0"
}

provider "google" {
  credentials = file("your_file")
  project     = "molten-enigma-184614"
}
