# Workload Identity Federation (WIF) Terraform Setup

This section provides two approaches to setting up Workload Identity Federation in GCP using Terraform:

- **Using the workload-identity-pool module**
- **Using GCP provider resources**

## Using the workload-identity-pool Module

For more details on the module, refer to the [module README.md](modules/README.md).

To see usage examples, visit the [samples](sample/module) directory.

## Using GCP Provider Resources

Setup varies depending on the realm of your integration:

- For the **us2 realm**, see the [us2 sample](sample/us2). It uses in assertion service account email

| Realm | sa_email                                                  |
|-------|-----------------------------------------------------------|
| us2   | splunk-observability@us2-env-181.iam.gserviceaccount.com  |


- For **other realms** (e.g., us0), see the [us0 sample](sample/us0). Please ensure `splunk_role_arn` variable is set to the correct value, depending on realm.


| Realm | splunk_role_arn |
|-------|------|
| us0   | arn:aws:sts::134183635603:assumed-role/us0-splunk-observability |
| us1   | arn:aws:sts::562691491210:assumed-role/us1-splunk-observability |
| jp0   | arn:aws:sts::947592474007:assumed-role/jp0-splunk-observability |
| au0   | arn:aws:sts::642047998396:assumed-role/au0-splunk-observability |
| eu0   | arn:aws:sts::214014584948:assumed-role/eu0-splunk-observability |
| eu1   | arn:aws:sts::797571435910:assumed-role/eu1-splunk-observability |
| eu2   | arn:aws:sts::417715959474:assumed-role/eu2-splunk-observability |
