#!/usr/bin/env python3
"""
GitHub Git Credential Helper (Python version)

Usage:
    git config --global credential.helper '/app/bin/git-credential-helper.py'
"""

import base64
import json
import os
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

try:
    from jwcrypto import jwk, jws

    HAVE_JWCRYPTO = True
except ImportError:
    HAVE_JWCRYPTO = False

TOKEN_CACHE_FILE = os.environ.get("TOKEN_CACHE_FILE", os.path.expanduser("~/.github-token"))

# ---------------------------------------------------------------------------
# JWT helpers
# ---------------------------------------------------------------------------


def _b64url_encode(data: bytes) -> str:
    """Base64url encode without padding."""
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def create_jwt(app_id: str, private_key_pem: str) -> str:
    """
    Create a GitHub App JWT using RS256.

    Tries jwcrypto first (cleaner), falls back to calling the system
    `openssl` binary so the script works in minimal environments.
    """
    now = int(time.time())
    iat = now - 60
    exp = now + 600

    header = {"typ": "JWT", "alg": "RS256"}
    payload = {"iat": iat, "exp": exp, "iss": app_id}

    header_b64 = _b64url_encode(json.dumps(header, separators=(",", ":")).encode())
    payload_b64 = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{header_b64}.{payload_b64}".encode()

    if HAVE_JWCRYPTO:
        key = jwk.JWK.from_pem(private_key_pem.encode())
        payload_bytes = json.dumps(payload, separators=(",", ":")).encode()
        protected_json = json.dumps({"typ": "JWT", "alg": "RS256"})
        sig = jws.JWS(payload=payload_bytes)
        sig.add_signature(key, alg="RS256", protected=protected_json)
        result = sig.serialize(compact=True)
        return result.decode() if isinstance(result, bytes) else result

    # Fallback: write key to a temp file and shell out to openssl
    import tempfile

    with tempfile.NamedTemporaryFile("w", suffix=".pem", delete=False) as fh:
        fh.write(private_key_pem)
        key_path = fh.name

    try:
        # openssl dgst -sha256 -sign key.pem  -> raw signature bytes
        proc = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_path],
            input=signing_input,
            capture_output=True,
            check=True,
        )
        signature_b64 = _b64url_encode(proc.stdout)
    finally:
        os.unlink(key_path)

    return f"{header_b64}.{payload_b64}.{signature_b64}"


# ---------------------------------------------------------------------------
# GitHub API
# ---------------------------------------------------------------------------


def fetch_installation_token(jwt: str, installation_id: str) -> str:
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    req = urllib.request.Request(
        url,
        method="POST",
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {jwt}",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Length": "0",
        },
    )
    with urllib.request.urlopen(req) as resp:
        body = resp.read().decode()
    return json.loads(body)["token"]


# ---------------------------------------------------------------------------
# Credential printing
# ---------------------------------------------------------------------------


def print_creds(token: str, username: str | None = None, cache: bool = True) -> None:
    if username is None:
        username = os.environ.get("GITHUB_USER", "x-access-token")

    sys.stdout.write("protocol=https\n")
    sys.stdout.write("host=github.com\n")
    sys.stdout.write(f"username={username}\n")
    sys.stdout.write(f"password={token}\n")
    sys.stdout.flush()

    if cache:
        cache_path = Path(TOKEN_CACHE_FILE)
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        cache_path.write_text(token)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    # 1. Explicit token from environment
    github_token = os.environ.get("GITHUB_TOKEN")
    if github_token:
        print_creds(github_token, cache=False)
        return 0

    # 2. Cached token on disk
    cache_path = Path(TOKEN_CACHE_FILE)
    if cache_path.is_file():
        cached = cache_path.read_text().strip()
        if cached:
            print_creds(cached, cache=False)
            return 0

    # 3. GitHub App → JWT → installation access token
    app_id = os.environ.get("github_app_id")
    installation_id = os.environ.get("github_app_installation_id")
    private_key = os.environ.get("github_app_private_key")

    if not (app_id and installation_id and private_key):
        sys.stderr.write("github_app_id, github_app_installation_id, github_app_private_key are required\n")
        return 1

    jwt = create_jwt(app_id, private_key)
    token = fetch_installation_token(jwt, installation_id)
    print_creds(token, cache=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
