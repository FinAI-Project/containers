FROM alpine
ARG AZCOPY_VERSION=10.31.0
RUN set -e; \
    apk update; \
    apk add --no-cache curl libc6-compat; \
    curl -fsSL "https://github.com/Azure/azure-storage-azcopy/releases/download/v${AZCOPY_VERSION}/azcopy_linux_amd64_${AZCOPY_VERSION}.tar.gz" | tar zxvf - -C /usr/local/bin --strip-components 1 "azcopy_linux_amd64_${AZCOPY_VERSION}/azcopy"; \
    rm -rf /var/cache/apk/*;
