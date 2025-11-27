#!/usr/bin/env sh

set -e

TOKEN_CACHE_FILE="${TOKEN_CACHE_FILE:-~/.github-token}"

print_creds() {
    skip_cache="$1"
    echo "protocol=https"
    echo "host=github.com"
    echo "username=${GITHUB_USER:-x-access-token}"
    echo "password=${GITHUB_TOKEN}"
    if [ -z "$skip_cache" ]; then
        echo -n "$GITHUB_TOKEN" > "$TOKEN_CACHE_FILE"
    fi
}

if [ -n "$GITHUB_TOKEN" ]; then
    print_creds from-env
    exit 0
fi

if [ -f "$TOKEN_CACHE_FILE" ]; then
    GITHUB_TOKEN=$(cat "$TOKEN_CACHE_FILE")
    print_creds from-cache
    exit 0
fi

if [ -z "$github_app_id" ] || [ -z "$github_app_installation_id" ] || [ -z "$github_app_private_key" ]; then
    >&2 echo "github_app_id, github_app_installation_id, github_app_private_key are required"
    exit 1
fi

now=$(date +%s)
iat=$((${now} - 60))
exp=$((${now} + 600))

b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

header_json='{"typ":"JWT","alg":"RS256"}'
header=$( echo -n "${header_json}" | b64enc )

payload_json='{"iat":'$iat',"exp":'$exp',"iss":"'$github_app_id'"}'
payload=$( echo -n "${payload_json}" | b64enc )

header_payload="${header}"."${payload}"
signature=$(
    openssl dgst -sha256 -sign <(echo -n "${github_app_private_key}") \
    <(echo -n "${header_payload}") | b64enc
)

JWT="${header_payload}"."${signature}"
GITHUB_TOKEN=$(curl -s -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${JWT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/app/installations/${github_app_installation_id}/access_tokens" | jq -r .token)
print_creds
