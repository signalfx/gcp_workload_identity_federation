# Workload Identity Federation Setup Utils
This repository provides tools to set up Workload Identity Federation in Google Cloud Platform (GCP) for granting access to Splunk integrations. Two setup approaches are available based on your requirements:
- [Terraform based solution](terraform/README.md)
- [CLI based solution (python script calling gcloud)](cli/README.md)

## Permissions

To create WIF resources you need the following permissions:
```
iam.googleapis.com/workloadIdentityPoolProviders.create
iam.googleapis.com/workloadIdentityPoolProviders.delete
iam.googleapis.com/workloadIdentityPoolProviders.undelete
iam.googleapis.com/workloadIdentityPoolProviders.update
iam.googleapis.com/workloadIdentityPools.create
iam.googleapis.com/workloadIdentityPools.delete
iam.googleapis.com/workloadIdentityPools.undelete
iam.googleapis.com/workloadIdentityPools.update
```
Alternatively, you can use the following predefined role:
- `roles/iam.workloadIdentityPoolAdmin`


Additionally, you need the permission to create IAM bindings:
- `resourcemanager.projects.setIamPolicy`
- `resourcemanager.folders.setIamPolicy`

You can also use predefined roles:
- `roles/resourcemanager.projectIamAdmin`
- `roles/resourcemanager.folderIamAdmin`