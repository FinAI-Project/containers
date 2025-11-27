import json
import logging
import os
import time
from datetime import datetime, timedelta, timezone

import jwt
import requests
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
GITHUB_API_ENDPOINT = "https://api.github.com"
GITHUB_APP_ID = os.getenv("github_app_id")
GITHUB_APP_INSTALLATION_ID = os.getenv("github_app_installation_id")
GITHUB_APP_PRIVATE_KEY = os.getenv("github_app_private_key")
GITHUB_TOKEN_ACCESS_REPOS = os.getenv("GITHUB_TOKEN_ACCESS_REPOS")
TOKEN_REFRESH_THRESHOLD = int(os.getenv("TOKEN_REFRESH_THRESHOLD", "600"))
TOKEN_CACHE_FILE = os.getenv("TOKEN_CACHE_FILE", "/tmp/token_cache.json")
AZURE_VAULT_URL = os.getenv("AZURE_VAULT_URL")
AZURE_SECRET_NAME = os.getenv("AZURE_SECRET_NAME", "github-access-token")

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL.upper(), logging.INFO),
    format="[%(name)s] [%(levelname)s] %(asctime)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def generate_access_token():
    """
    Generate a GitHub App installation access token with repository permissions.

    API docs: https://docs.github.com/en/rest/apps/apps?apiVersion=2022-11-28#create-an-installation-access-token-for-an-app

    Returns:
        dict: A dictionary containing access token and expiration time
    """

    now = int(time.time())
    jwt_token = jwt.encode({"iat": now, "exp": now + 600, "iss": GITHUB_APP_ID}, GITHUB_APP_PRIVATE_KEY, algorithm="RS256")

    logger.debug("Fetching access token from GitHub")
    api_url = f"{GITHUB_API_ENDPOINT}/app/installations/{GITHUB_APP_INSTALLATION_ID}/access_tokens"
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    logger.debug(f"Request headers: {headers}")
    payload = None
    if GITHUB_TOKEN_ACCESS_REPOS:
        payload = {
            "repositories": GITHUB_TOKEN_ACCESS_REPOS.split(","),
            "permissions": {"contents": "read"},
        }
    logger.debug(f"Request payload: {payload}")

    response = requests.post(api_url, headers=headers, json=payload)
    response.raise_for_status()
    logger.info("Access token fetched successfully")
    data = response.json()
    logger.debug(f"Response data: {data}")
    return {k: data[k] for k in ("token", "expires_at") if k in data}


def get_installation_token():
    """Get installation token from cache or generate a new one"""

    if os.path.exists(TOKEN_CACHE_FILE):
        try:
            with open(TOKEN_CACHE_FILE, "r") as f:
                cache_data = json.load(f)
            expires_at = datetime.strptime(cache_data["expires_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
            if (expires_at - datetime.now(timezone.utc)) > timedelta(seconds=TOKEN_REFRESH_THRESHOLD):
                logger.debug("Token is still valid")
                return cache_data["token"]
        except (json.JSONDecodeError, KeyError) as e:
            logger.warning(f"Error loading token cache: {e}")

    data = generate_access_token()
    with open(TOKEN_CACHE_FILE, "w") as f:
        json.dump(data, f)
    save_token(data)

    return data["token"]


def save_token(data: dict):
    """
    Save GitHub access token to Azure Key Vault securely

    Args:
        token (str): GitHub installation access token to be stored
    """

    logger.debug("Saving access token to Azure Key Vault")
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=AZURE_VAULT_URL, credential=credential)
    client.set_secret(
        AZURE_SECRET_NAME,
        data["token"],
        content_type="text/plain",
        expires_on=datetime.strptime(data["expires_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc),
    )
    logger.info("Token successfully saved to Azure Key Vault")


if __name__ == "__main__":
    if not all([GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID, GITHUB_APP_PRIVATE_KEY]):
        raise ValueError("Missing required environment variables")

    retry_count = 0
    while True:
        try:
            get_installation_token()
            retry_count = 0
            sleep_time = 300
        except Exception as e:
            logger.error("Error fetching token: %s", str(e))
            retry_count += 1
            sleep_time = min(300, retry_count * 10)
        time.sleep(sleep_time)
