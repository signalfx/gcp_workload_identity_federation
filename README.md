# Workload Identity Federation Setup Script

This Python script automates the setup of **Google Cloud Workload Identity Federation** for Splunk integrations. It uses `gcloud` commands in the shell to create and configure resources, including:
- Workload Identity Pools
- Identity Providers
- IAM Policy Bindings

## Features
- Support setting up on GCP or AWS Splunk realms
- Allows switching between two modes:
    1. **Automatic mode**: Runs all steps without interruption.
    2. **Interactive mode**: Asks for confirmation when resource already exists.
- Retrieves **AWS account ID** from the provided role ARN.
- **Fetches GCP project number** automatically if not provided.
- Generates **credentials configuration file** for the identity federation.

## Prerequisites

Before running the script, ensure that the following are installed and configured:

1. **Google Cloud SDK (`gcloud`)**:
    - Install [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/docs/install) if you haven't already.
    - Authenticate with your GCP account using:
      ```bash
      gcloud auth login
      ```
    - Set the active project:
      ```bash
      gcloud config set project YOUR_PROJECT_ID
      ```

2. **Python 3.x**:
    - Make sure you have Python 3 installed.
    - You can check your Python version using:
      ```bash
      python --version
      ```

3. Permissions

For create WIF resources you need these permissions:
- iam.googleapis.com/workloadIdentityPoolProviders.create
- iam.googleapis.com/workloadIdentityPoolProviders.delete
- iam.googleapis.com/workloadIdentityPoolProviders.undelete
- iam.googleapis.com/workloadIdentityPoolProviders.update
- iam.googleapis.com/workloadIdentityPools.create
- iam.googleapis.com/workloadIdentityPools.delete
- iam.googleapis.com/workloadIdentityPools.undelete
- iam.googleapis.com/workloadIdentityPools.update

You can also use such predefined role:
- roles/iam.workloadIdentityPoolAdmin


You need to have also permission to create IAM binding, you need to have permission
- resourcemanager.projects.setIamPolicy

You can also use predefined role:
- roles/resourcemanager.projectIamAdmin

## Running the Script
You can run the script with the following arguments:

Required Arguments:

- project_id: The GCP project ID for which access will be granted
- realm_name: [The Splunk Observability realm](https://docs.splunk.com/observability/en/admin/references/organizations.html) to configure. It can be found at: User Profile -> Organizations

Optional Arguments:

- --output_file_path: Path to save the credentials file. Default is credentials.json.
- --project_number: GCP project number (will be automatically fetched if not provided).
- --additional_project_ids: A list of additional project IDs for which access will be granted (defaults to an empty list).
- --ignore_existing: In case of already existing resources, continue without ask (default is false).
- --role: Specify role which will be granted (default is roles/viewer).

- Example :

```bash
python setup_wif.py --ignore_existing  enigma-123 us1 
```