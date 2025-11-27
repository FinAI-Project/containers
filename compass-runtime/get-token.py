import os
import sys
import time

import jwt
import requests


def generate_jwt(app_id, private_key):
    if not app_id:
        raise ValueError("github_app_id is required.")
    if not private_key:
        raise ValueError("github_app_private_key is required.")
    now = int(time.time())
    payload = {"iat": now, "exp": now + 600, "iss": app_id}
    token = jwt.encode(payload, private_key, algorithm="RS256")
    return token


def get_access_token(token, installation_id):
    if not token:
        raise ValueError("Failed to generate jwt.")
    if not installation_id:
        raise ValueError("github_app_installation_id is required.")
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github.v3+json"}
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    response = requests.post(url, headers=headers, timeout=5)
    if response.status_code == 201:
        return response.json().get("token")
    raise ValueError("Failed to generate access token.")


if __name__ == "__main__":
    try:
        jwt_token = generate_jwt(os.getenv("github_app_id"), os.getenv("github_app_private_key"))
        access_token = get_access_token(jwt_token, os.getenv("github_app_installation_id"))
        print(access_token)
        sys.exit(0)
    except Exception as ex:  # pylint: disable=broad-exception-caught
        print(f"error: {ex}")
        sys.exit(1)
