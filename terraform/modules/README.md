# WIF Terraform Module

This Terraform module automates the setup of **Google Cloud Workload Identity Federation** for Splunk Observability GCP integrations. It manages:
- Workload Identity Pools
- Identity Providers
- IAM Policy Bindings
- Generate WIF configuration file

## Prerequisites

Before running the script, ensure that the following are installed and configured:

1. **Google Cloud SDK (`gcloud`)**:
    - Install [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/docs/install) if you haven't already.
    - Authenticate with your GCP account using:
      ```bash
      gcloud auth login
      gcloud auth application-default login
      ```
    - Set the active project:
      ```bash
      gcloud config set project YOUR_PROJECT_ID
      ```

## Module variables

- `project_id` (string, required): The GCP project ID.
- `realm_name` (string, required):  [The Splunk Observability realm](https://docs.splunk.com/observability/en/admin/references/organizations.html) to configure. It can be found at: User Profile -> Organizations.
- `additional_project_ids` (list(string), optional, default: []): A list of additional project IDs for which access will be granted (IAM bindings will be added). Use this if you want to explicitly grant permissions to each projects. For automatic project synchronization, use `folder_ids`.
- `folder_ids` (list(string), optional, default: []): A list of folder IDs for which access will be granted (IAM bindings will be added).
- `roles` (list(string), optional, default: ["roles/viewer", "roles/browser", "roles/serviceusage.serviceUsageConsumer"]). List of roles that will be added to projects in `project_id`, `additional_project_ids` and folders in `folder_ids`.
- `custom_pool_name` (string, optional, default: ""): Custom name for the Workload Identity Pool. If not provided, a default name will be generated based on the realm name.
- `custom_provider_name` (string, optional, default: ""): Custom name for the Workload Identity Provider. If not provided, a default name will be generated based on the realm name. 

## Outputs

`credentials_config`: Content of the generated config for Workload Identity Federation. It can be used to set up the integration

## Notes

- When you create IAM binding and Splunk integration in one terraform apply, it may occasionally fail with an error indicating that certain permissions are missing (e.g., monitoring.metricDescriptors.list, compute.instances.list). 
This is likely due to IAM roles taking some time to propagate. In such cases, re-running the terraform apply command usually resolves the issue.
