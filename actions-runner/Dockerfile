# https://github.com/actions/runner/blob/main/images/Dockerfile
FROM ghcr.io/actions/actions-runner

RUN set -e; \
    sudo apt-get update; \
    sudo apt-get upgrade -y; \
    sudo apt-get install -y --no-install-recommends build-essential cmake rsync; \
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; \
    curl -sL https://aka.ms/downloadazcopy-v10-linux | sudo tar zxvf - -C /usr/local/bin --strip-components 1; \
    sudo apt-get clean; \
    sudo rm -rf /var/lib/apt/lists/*;