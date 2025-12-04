# https://mcr.microsoft.com/en-us/artifact/mar/azure-cli
FROM mcr.microsoft.com/azure-cli:azurelinux3.0
RUN set -e; \
    tdnf update; \
    tdnf install -y azcopy rsync; \
    tdnf clean all; \
    rm -rf /var/cache/tdnf/* /tmp/*; \
    azcopy --version; \
    rsync --version;
