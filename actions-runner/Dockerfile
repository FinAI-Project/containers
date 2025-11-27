FROM ghcr.io/actions/actions-runner

RUN set -e; \
    sudo apt-get update; \
    sudo apt-get upgrade -y; \
    sudo apt-get install -y --no-install-recommends build-essential; \
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; \
    sudo sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin; \
    sudo apt-get clean; \
    sudo rm -rf /var/lib/apt/lists/*;
