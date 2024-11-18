import sys
import requests
import os
import string
import random
import unittest
from dotenv import load_dotenv

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import setup_wif
from setup_wif import Result

GCP_PROJECT_ID = 'molten-enigma-184614'


def step(text):
    print("*" * 50)
    print(text)
    print("*" * 50)


def generate_random_string(length=28):
    characters = string.ascii_lowercase + string.digits
    return ''.join(random.choice(characters) for _ in range(length))


def create_integration(project_id, wif_config, url, token, pool_name):
    step("CREATE INTEGRATION")

    headers = {
        "accept": "application/json, text/plain, */*",
        "x-sf-token": token,
        "content-type": "application/json"
    }

    payload = {
        "enabled": True,
        "importGCPMetrics": True,
        "includeList": [],
        "name": "test/" + pool_name,
        "pollRate": 120000,
        "authMethod": "WORKLOAD_IDENTITY_FEDERATION",
        "workloadIdentityFederationConfigs": [
            {
                "projectId": project_id,
                "wifConfig": wif_config
            }
        ],
        "services": [],
        "type": "GCP",
        "useMetricSourceProjectForQuota": False,
        "whitelist": []
    }

    response = requests.post(f"{url}/v2/integration", headers=headers, json=payload)
    response.raise_for_status()
    return response.json()["id"]


def delete_integration(url, token, id):
    step("DELETE INTEGRATION")

    headers = {
        "x-sf-token": token,
    }
    response = requests.delete(url + f"/v2/integration/{id}", headers=headers)
    response.raise_for_status()


class TestWIFIntegration(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        load_dotenv()
        cls.url_aws = os.environ['TEST_URL_AWS']
        cls.token_aws = os.environ['TEST_TOKEN_AWS']
        cls.url_gcp = os.environ['TEST_URL_GCP']
        cls.token_gcp = os.environ['TEST_TOKEN_GCP']

    def setUp(self):
        id_aws = generate_random_string(26)
        id_gcp = generate_random_string(26)
        self.pool_name_aws = 'test-' + str(id_aws)
        self.provider_name_aws = 'test-' + str(id_aws)
        self.pool_name_gcp = 'test-' + str(id_gcp)
        self.provider_name_gcp = 'test-' + str(id_gcp)

    def test_integration_is_auth(self):
        test_cases = [
            {
                "lab_name": "lab0",
                "config": {
                    "type": "aws",
                    "role": "arn:aws:sts::134183635603:assumed-role/lab0-splunk-observability"
                },
                "url": self.url_aws,
                "token": self.token_aws,
                "pool_name": self.pool_name_aws,
                "provider_name": self.provider_name_aws
            },
            {
                "lab_name": "lab1",
                "config": {
                    "type": "gcp",
                    "sa_email": "splunk-observability@lab1-env-716.iam.gserviceaccount.com"
                },
                "url": self.url_gcp,
                "token": self.token_gcp,
                "pool_name": self.pool_name_gcp,
                "provider_name": self.provider_name_gcp
            }
        ]

        for test_case in test_cases:
            with self.subTest(test_case=test_case):
                pool_result, provider_result, wif_config = setup_wif.main(
                    ['--no_interactive', '--pool_name', test_case["pool_name"], '--provider_name', test_case["provider_name"], GCP_PROJECT_ID, test_case["lab_name"]],
                    {test_case["lab_name"]: test_case["config"]}
                )
                self.assertEqual(pool_result, Result.CREATED)
                self.assertEqual(provider_result, Result.CREATED)

                id = create_integration(GCP_PROJECT_ID, wif_config, test_case["url"], test_case["token"], test_case["pool_name"])
                delete_integration(test_case["url"], test_case["token"], id)

    def tearDown(self):
        self.cleanup(self.pool_name_aws, self.provider_name_aws)
        self.cleanup(self.pool_name_gcp, self.provider_name_gcp)

    def cleanup(self, pool_name, provider_name):
        step("CLEANUP")
        setup_wif.run_command(
            [
                "gcloud", "iam", "workload-identity-pools", "providers", "delete", provider_name,
                "--project", GCP_PROJECT_ID,
                "--location", "global",
                "--workload-identity-pool", pool_name,
                "--quiet"
            ], fail_on_error=False
        )
        setup_wif.run_command(
            ["gcloud", "iam",
             "workload-identity-pools", "delete", pool_name,
             "--project", GCP_PROJECT_ID,
             "--location", "global",
             "--quiet"
             ], fail_on_error=False
        )


if __name__ == '__main__':
    unittest.main()
