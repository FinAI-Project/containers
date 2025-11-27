FROM alpine

WORKDIR /app

COPY *.sh /app

RUN set -e; \
    apk add --no-cache curl openssl git jq; \
    rm -rf /var/cache/apk/*; \
    chmod a+x *.sh; \
    git config --global credential.helper '/app/git-credential-helper.sh'; \
    git config --global --add safe.directory /app/code;

CMD ["/app/github-clone.sh"]