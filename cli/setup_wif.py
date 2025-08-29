#!/usr/bin/env python3
import subprocess
import json
import argparse
import sys
from enum import Enum
from typing import Tuple

REALMS_JSON = "../realms.json"


class Result(Enum):
    CREATED = 1
    EXISTING = 2
    NOOP = 3
    ERROR = 3


class WIFProvider:
    def __init__(self, project_number, project_id, realm_name, pool_name, provider_name, auto_mode=False, dry_run=False):
        self.project_id = project_id
        self.auto_mode = auto_mode
        self.project_number = project_number
        self.realm_name = realm_name
        self.pool_name = pool_name
        self.provider_name = provider_name
        self.dry_run = dry_run

    def create_identity_pool(self) -> tuple[str, Result]:
        command = [
            "gcloud", "iam", "workload-identity-pools", "create", self.pool_name,
            "--project", self.project_id,
            "--location", "global",
            "--display-name", self.pool_name
        ]
        return run_command(command, auto_mode=self.auto_mode, dry_run=self.dry_run)

    def add_iam_policy_binding(self, project_id, role) -> tuple[str, Result]:
        raise NotImplementedError("This method should be implemented by subclasses.")

    def create_cred_config(self, output_file):
        raise NotImplementedError("This method should be implemented by subclasses.")


class AWSWIFProvider(WIFProvider):
    def __init__(self, project_number, project_id, realm_name, account_id, aws_role_arn, pool_name, provider_name, auto_mode=False, dry_run=False):
        super().__init__(project_number, project_id, realm_name, pool_name, provider_name, auto_mode, dry_run)
        self.account_id = account_id
        self.aws_role_arn = aws_role_arn

    def create_provider(self) -> tuple[str, Result]:
        command = [
            "gcloud", "iam", "workload-identity-pools", "providers", "create-aws", self.provider_name,
            "--workload-identity-pool", self.pool_name,
            "--account-id", self.account_id,
            "--location", "global",
            f'--attribute-condition=attribute.aws_role in ["{self.aws_role_arn}"]',
            "--project", self.project_id
        ]
        return run_command(command, auto_mode=self.auto_mode, dry_run=self.dry_run)

    def add_iam_policy_binding(self, project_id, role):
        member = f'principalSet://iam.googleapis.com/projects/{self.project_number}/locations/global/workloadIdentityPools/{self.pool_name}/attribute.aws_role/{self.aws_role_arn}'
        command = [
            "gcloud", "projects", "add-iam-policy-binding", project_id,
            "--member", member,
            "--role", role,
            "--condition=None"
        ]
        return run_command(command, dry_run=self.dry_run)

    def create_cred_config(self, output_file):
        command = [
            "gcloud", "iam", "workload-identity-pools", "create-cred-config",
            f"projects/{self.project_number}/locations/global/workloadIdentityPools/{self.pool_name}/providers/{self.provider_name}",
            "--aws",
            f"--output-file={output_file}"
        ]
        run_command(command, dry_run=self.dry_run)
        if not self.dry_run:
            with open(output_file, 'r') as f:
                config_content = f.read()
                print(f"\nGenerated AWS Credential Config:\n{config_content}\n")
                return config_content


# GCP-specific WIF setup class
class GCPWIFProvider(WIFProvider):
    def __init__(self, project_number, project_id, realm_name, sa_email, pool_name, provider_name, auto_mode=False, dry_run=False):
        super().__init__(project_number, project_id, realm_name, pool_name, provider_name, auto_mode, dry_run)
        self.sa_email = sa_email

    def create_provider(self):
        command = [
            "gcloud", "iam", "workload-identity-pools", "providers", "create-oidc", self.provider_name,
            "--workload-identity-pool", self.pool_name,
            "--location", "global",
            "--issuer-uri", "https://accounts.google.com",
            "--attribute-mapping=google.subject=assertion.email",
            f'--attribute-condition=google.subject in [\'{self.sa_email}\']',
            "--project", self.project_id
        ]
        return run_command(command, auto_mode=self.auto_mode, dry_run=self.dry_run)

    def add_iam_policy_binding(self, project_id, role):
        member = f'principal://iam.googleapis.com/projects/{self.project_number}/locations/global/workloadIdentityPools/{self.pool_name}/subject/{self.sa_email}'
        command = [
            "gcloud", "projects", "add-iam-policy-binding", project_id,
            "--member", member,
            "--role", role,
            "--condition=None"
        ]
        return run_command(command, dry_run=self.dry_run)

    def create_cred_config(self, output_file):
        source_url = (f"http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?"
                      f"audience=//iam.googleapis.com/projects/{self.project_number}/locations/global/workloadIdentityPools/"
                      f"{self.pool_name}/providers/{self.provider_name}")

        command = [
            "gcloud", "iam", "workload-identity-pools", "create-cred-config",
            f"projects/{self.project_number}/locations/global/workloadIdentityPools/{self.pool_name}/providers/{self.provider_name}",
            f"--credential-source-url={source_url}",
            "--credential-source-headers=Metadata-Flavor=Google",
            "--format=yaml",
            f"--output-file={output_file}"
        ]
        run_command(command, dry_run=self.dry_run)

        if not self.dry_run:
            with open(output_file, 'r') as f:
                config_content = f.read()
                print(f"\nGenerated GCP Credential Config:\n{config_content}\n")
                return config_content


def run_command(command, auto_mode=False, verbose=True, dry_run=False, fail_on_error=True) -> Tuple[str, Result]:
    command_str = ' '.join(command)
    if dry_run:
        print(f"Command: \n{command_str}")
        return "", Result.NOOP
    print(f"Executing command: \n{command_str}") if verbose else None
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        if verbose:
            print(f"Command output: {result.stdout.strip()}\n")
            print(f"Executed successfully\n")

        return result.stdout.strip(), Result.CREATED
    except subprocess.CalledProcessError as e:
        if "ALREADY_EXISTS" in e.stderr:
            already_exists(e.stderr, auto_mode)
            return "", Result.EXISTING
        print(f"Error executing command: {command_str}")
        print(f"Status code: {e.returncode}")
        print(f"Error message: {e.stderr}")
        if fail_on_error:
            sys.exit(1)
        return "", Result.ERROR


def get_project_number(project_id):
    command = ["gcloud", "projects", "describe", project_id, "--format=value(projectNumber)"]
    project_number = run_command(command, verbose=False)
    if not project_number:
        print(f"Error: Unable to retrieve project number for project ID: {project_id}")
        sys.exit(1)
    return project_number


def step(step_description):
    print("-" * 20)
    print(step_description)


def already_exists(output, auto_mode):
    print("-" * 20)
    print(f"\nSeems like resource already exists, response was:\n\t{output}")
    if auto_mode:
        print("Continue execution")
        return
    response = input(f"Do you want to continue? (Y/n): ")
    if response.lower() != "" and response.lower() != "y":
        exit(1)


def load_realms(file):
    if isinstance(file, str):
        with open(file, 'r') as f:
            return json.load(f)
    return file


def extract_account_id(arn):
    return arn.split(':')[4]


class CustomArgumentParser(argparse.ArgumentParser):
    def __init__(self, realm_file, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.realm_file = realm_file

    def print_help(self, *args, **kwargs):
        super().print_help(*args, **kwargs)
        print("\nAvailable realms:")

        print(", ".join(load_realms(self.realm_file).keys()))


# Main function to handle the WIF setup for AWS
def main(args=None, realms_config=REALMS_JSON):
    parser = CustomArgumentParser(realms_config, description="Setup GCP WIF for Splunk Observability integrations and generate a config file")
    parser.add_argument("project_id", help="GCP project ID for which WIF will be configured and assigned permissions")
    parser.add_argument("realm_name", help="Name of your Splunk Observability realm. It can be found at: User Profile -> Organizations")
    parser.add_argument("--project_number", help="Numeric GCP project number (optional, fetched if not provided)")
    parser.add_argument("--output_file", help="Output file path for the credential config (default: gcp_wif_config.json)",
                        default="gcp_wif_config.json")
    parser.add_argument("--additional_project_id", action='append', default=None,
                        help="Optional list of additional project IDs for which access will be granted. You can provide multiple roles by repeating --additional_project_id")
    parser.add_argument("--ignore_existing", action="store_true", help="In case of already existing resources, continue without ask")
    parser.add_argument("--gcp_role", default=None, action='append',
                        help="Specify role which will be granted. You can provide multiple roles by repeating --gcp_role. By default it uses 'roles/viewer'")
    parser.add_argument("--pool_name", help="Custom workload identity pool name", default="splunk-identity-pool")
    parser.add_argument("--provider_name", help="Custom workload identity provider name", default="splunk-provider")
    parser.add_argument("--dry_run", help="Just print what commands will be executed", action="store_true")
    parser.add_argument("--no_interactive", action="store_true")

    project_ids = []
    args = parser.parse_args(args)
    project_id = args.project_id
    realm_name = args.realm_name
    project_number = args.project_number
    output_file = args.output_file
    auto_mode = args.ignore_existing or args.no_interactive
    pool_name = args.pool_name
    provider_name = args.provider_name

    if args.gcp_role:
        roles = args.gcp_role
    else:
        roles = ["roles/viewer"]

    project_ids.insert(0, project_id)
    if args.additional_project_id:
        project_ids = project_ids + args.additional_project_id

    realms = load_realms(realms_config)

    if realm_name not in realms:
        print(f"Error: Realm '{realm_name}' not found.")
        print("Available realms:")
        print(", ".join(realms.keys()))
        sys.exit(1)

    if args.dry_run:
        print("RUN IN DRY MODE")
        print("No command will be actually executed")
        print("*" * 40)

    realm_info = realms[realm_name]
    realm_type = realm_info["type"]
    print(f"Realm type: {realm_type}")

    if not project_number:
        print("Fetching project number")
        project_number, _ = get_project_number(project_id)

    # Get user approval for resources to be created
    resources_to_create = [
        f"Workload Identity Pool: {pool_name}",
        f"Workload Identity Provider: {provider_name}",
    ]
    resources_to_create = resources_to_create + [f"Provider added as member to IAM role: {role}" for role in roles]
    if not args.dry_run and not args.no_interactive:
        get_user_approval(resources_to_create)

    if realm_type == "aws":
        aws_role_arn = realm_info["role"]
        account_id = extract_account_id(aws_role_arn)
        provider = AWSWIFProvider(project_number, project_id, realm_name, account_id, aws_role_arn, pool_name, provider_name, auto_mode, args.dry_run)
    else:
        provider = GCPWIFProvider(project_number, project_id, realm_name, realm_info["sa_email"], pool_name, provider_name, auto_mode, args.dry_run)

    step("Creating identity pool")
    _, pool_result = provider.create_identity_pool()
    step("Creating provider")
    _, provider_result = provider.create_provider()
    for project_id in project_ids:
        step(f"Adding IAM policy binding for {project_id}")
        for role in roles:
            provider.add_iam_policy_binding(project_id, role)
    step(f"Creating credential config")
    cred_config = provider.create_cred_config(output_file)

    if not args.dry_run:
        print_created_resources(resources_to_create)
        print(f"WIF setup completed.")
    return pool_result, provider_result, cred_config


def get_user_approval(resources):
    print("The following resources will be created:")
    for resource in resources:
        print(f"- {resource}")
    approval = input("Do you approve the creation of these resources? (Y/n): ").strip().lower()
    if approval.lower() != "" and approval.lower() != "y":
        print("Operation cancelled by user.")
        exit(1)


def print_created_resources(resources):
    print("\nThe following resources have been created:")
    for resource in resources:
        print(f"- {resource}")


if __name__ == "__main__":
    main()
