# Workload Identity Federation Setup Script

This Python script automates the setup of **Google Cloud Workload Identity Federation** for Splunk integrations. It uses `gcloud` commands in the shell to create and configure resources, including:
- Workload Identity Pools
- Identity Providers
- IAM Policy Bindings

## Features
- Supports setting up on GCP or AWS Splunk realms
- Allows switching between two modes:
    1. **Automatic mode**: Runs all steps without interruption.
    2. **Interactive mode**: Asks for confirmation when a resource already exists.
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


## Running the Script
You can run the script with the following arguments:

Required Arguments:

- `project_id`: The GCP project ID for which access will be granted.
- `realm_name`: [The Splunk Observability realm](https://docs.splunk.com/observability/en/admin/references/organizations.html) to configure. It can be found at: User Profile -> Organizations.

Optional Arguments:

- `--output_file_path`: Path to save the credentials file. Default is gcp_wif_config.json.
- `--project_number`: GCP project number (will be automatically fetched if not provided).
- `--additional_project_id`: Additional project ID for which access will be granted. You can provide multiple projects by repeating `--additional_project_id`.
- `--folder_id`: Folder ID for which access will be granted. Use for auto synchronization of projects in the folder. You can provide multiple folders by repeating `--folder_id`.
- `---include_multiproject_roles`: Include roles enabling automatic synchronization of projects that have necessary permissions. Those roles are `roles/browser` and `roles/serviceusage.serviceUsageConsumer`.
- `--ignore_existing`: In case of already existing resources, continue without ask (default is false).
- `--gcp_role`: Specify role which will be granted. You can provide multiple roles by repeating `--gcp_role`. Default is `roles/viewer`.
- `--pool_name`: Custom workload identity pool name (default is splunk-identity-pool).
- `--provider_name`: Custom workload identity provider name (default is splunk-provider).
- `--dry_run`: Just print what commands will be executed.

Example:

```bash
python setup_wif.py --ignore_existing enigma-123 us1 
```

## Modifying config to API request

When you are planning to set up an integration using API, then config needs to be encoded into string. It can be achieved via the following command:

```bash
jq -c '.' <<config_path>> | jq tostring
```
